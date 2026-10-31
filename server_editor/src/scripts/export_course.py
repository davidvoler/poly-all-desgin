"""Copy a course and everything under it from one Postgres database to another.

Copies: course -> modules -> lessons -> exercises, plus the module videos and
course words. Rows get new ids in the target and every course_id / module_id /
lesson_id reference is remapped. Soft-deleted rows are skipped.

The whole copy runs in a single transaction on the target: it either fully
succeeds or leaves the target untouched.

Usage (from server/src):
    python -m scripts.export_course 12 \
        --target postgresql://user:pass@host:5432/polyglots

    # source defaults to the POSTGRES_* env vars (same as the app)
    python -m scripts.export_course 12 --source postgresql://... --target postgresql://...

    # check what would be copied without writing anything
    python -m scripts.export_course 12 --target postgresql://... --dry-run
"""
import argparse
import asyncio
import os
import sys

from psycopg import AsyncConnection
from psycopg.rows import dict_row
from psycopg.types.json import Jsonb

# allow `python scripts/export_course.py` as well as `python -m scripts.export_course`
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from utils.db import get_pg_connection_string  # noqa: E402


class Copier:
    def __init__(self, src: AsyncConnection, dst: AsyncConnection):
        self.src = src
        self.dst = dst
        self._columns: dict[str, dict[str, str]] = {}

    async def target_columns(self, table: str) -> dict[str, str]:
        """Column name -> data type of a target table (handles schema drift between DBs)."""
        if table not in self._columns:
            schema, name = table.split(".")
            cur = await self.dst.execute(
                """SELECT column_name, data_type FROM information_schema.columns
                   WHERE table_schema = %s AND table_name = %s""",
                (schema, name),
            )
            cols = {r["column_name"]: r["data_type"] for r in await cur.fetchall()}
            if not cols:
                raise RuntimeError(f"Table {table} does not exist in the target database")
            self._columns[table] = cols
        return self._columns[table]

    async def fetch(self, sql: str, params: tuple) -> list[dict]:
        cur = await self.src.execute(sql, params)
        return await cur.fetchall()

    async def insert(self, table: str, pk: str, row: dict) -> int:
        """Insert a row (minus its primary key) into the target, return the new id."""
        cols = await self.target_columns(table)
        data = {k: v for k, v in row.items() if k != pk and k in cols}
        values = [
            Jsonb(v) if cols[k] in ("json", "jsonb") and v is not None else v
            for k, v in data.items()
        ]
        names = ", ".join(data)
        placeholders = ", ".join(["%s"] * len(data))
        cur = await self.dst.execute(
            f"INSERT INTO {table} ({names}) VALUES ({placeholders}) RETURNING {pk}", values
        )
        return (await cur.fetchone())[pk]


def remap(row: dict, field: str, id_map: dict[int, int]) -> bool:
    """Swap row[field] to its new id. False if it points at a row we didn't copy."""
    old = row.get(field)
    if old is None:
        return True
    if old not in id_map:
        return False
    row[field] = id_map[old]
    return True


async def export_course(src: AsyncConnection, dst: AsyncConnection, course_id: int) -> dict:
    c = Copier(src, dst)
    counts = {}

    courses = await c.fetch("SELECT * FROM course.course WHERE course_id = %s", (course_id,))
    if not courses:
        raise RuntimeError(f"Course {course_id} not found in the source database")
    new_course_id = await c.insert("course.course", "course_id", courses[0])
    course_map = {course_id: new_course_id}
    counts["course"] = 1

    module_map: dict[int, int] = {}
    modules = await c.fetch(
        "SELECT * FROM course.module WHERE course_id = %s AND deleted IS NOT TRUE ORDER BY weight, module_id",
        (course_id,),
    )
    for m in modules:
        old_id = m["module_id"]
        m["course_id"] = new_course_id
        module_map[old_id] = await c.insert("course.module", "module_id", m)
    counts["modules"] = len(module_map)

    lesson_map: dict[int, int] = {}
    lessons = await c.fetch(
        "SELECT * FROM course.lesson WHERE course_id = %s AND deleted IS NOT TRUE ORDER BY weight, lesson_id",
        (course_id,),
    )
    for l in lessons:
        old_id = l["lesson_id"]
        l["course_id"] = new_course_id
        if not remap(l, "module_id", module_map):
            continue  # lesson of a deleted module
        lesson_map[old_id] = await c.insert("course.lesson", "lesson_id", l)
    counts["lessons"] = len(lesson_map)

    # Exercises can be linked by course_id or only by lesson_id, so match either.
    exercises = await c.fetch(
        """SELECT * FROM course.exercise
           WHERE course_id = %s OR lesson_id = ANY(%s)
           ORDER BY weight, exercise_id""",
        (course_id, list(lesson_map)),
    )
    n = 0
    for e in exercises:
        e["course_id"] = new_course_id
        if not (remap(e, "lesson_id", lesson_map) and remap(e, "module_id", module_map)):
            continue
        await c.insert("course.exercise", "exercise_id", e)
        n += 1
    counts["exercises"] = n

    # Module videos (lesson video previews read the module's video url).
    videos = await c.fetch(
        "SELECT * FROM course.video WHERE course_id = %s AND deleted IS NOT TRUE ORDER BY weight, video_id",
        (course_id,),
    )
    n = 0
    for v in videos:
        v["course_id"] = new_course_id
        if not remap(v, "module_id", module_map):
            continue
        await c.insert("course.video", "video_id", v)
        n += 1
    counts["videos"] = n

    words = await c.fetch(
        "SELECT * FROM course.words WHERE course_id = %s AND deleted IS NOT TRUE ORDER BY weight, word_id",
        (course_id,),
    )
    n = 0
    for w in words:
        if not remap(w, "course_id", course_map) or not remap(w, "module_id", module_map):
            continue
        await c.insert("course.words", "word_id", w)
        n += 1
    counts["words"] = n

    counts["new_course_id"] = new_course_id
    return counts


async def main() -> None:
    parser = argparse.ArgumentParser(description="Copy a course to another database")
    parser.add_argument("course_id", type=int, help="course_id in the source database")
    parser.add_argument("--source", default=None,
                        help="source Postgres URL (default: POSTGRES_* env vars)")
    parser.add_argument("--target", required=True, help="target Postgres URL")
    parser.add_argument("--dry-run", action="store_true",
                        help="run the copy, then roll it back")
    args = parser.parse_args()

    source_url = args.source or get_pg_connection_string()
    if source_url == args.target:
        sys.exit("Source and target are the same database")

    src = await AsyncConnection.connect(source_url, row_factory=dict_row, autocommit=True)
    dst = await AsyncConnection.connect(args.target, row_factory=dict_row)
    try:
        try:
            counts = await export_course(src, dst, args.course_id)
        except Exception:
            await dst.rollback()
            raise
        if args.dry_run:
            await dst.rollback()
            print("Dry run, nothing written. Would copy:")
        else:
            await dst.commit()
            print("Copied:")
        for k, v in counts.items():
            print(f"  {k}: {v}")
    finally:
        await src.close()
        await dst.close()


if __name__ == "__main__":
    asyncio.run(main())
