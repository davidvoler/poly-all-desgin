from datetime import datetime
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from school.models import school
from utils.db import get_query_results
from utils.auth_deps import current_school, current_school_user, current_school_user_full
from models.auth import  SchoolUser
router = APIRouter()


@router.get("/courses")
async def get_courses(school_user: SchoolUser = Depends(current_school_user)):
    if not school_user:
        raise HTTPException(status_code=401, detail="Not signed in")
    roles = school_user.roles
    params = []
    where = ''
    if 'admin' in roles or 'super_editor' in roles or 'editor' in roles  or 'teacher' in roles:
        where = 'school_id = %s' 
        params = [school_user.school_id] 
    elif 'editor' in roles:
        where = 'school_id = %s and user_id = %s' 
        params = [school_user.school_id, school_user.user_id]   
    sql = f"""
        SELECT * FROM course_simple.courses
        WHERE {where}"""
    rows = await get_query_results(sql, params)
    results = [r for r in rows]
    return results

@router.get("/school_users")
async def get_school_users(school_user: SchoolUser = Depends(current_school_user)):
    if not school_user:
        raise HTTPException(status_code=401, detail="Not signed in")
    roles = school_user.roles
    params = []
    where = ''
    if 'admin' in roles or 'super_admin' in roles  or 'teacher' in roles:
        params = [school_user.school_id] 
    else:
        raise HTTPException(status_code=403, detail="Forbidden")    
    sql = f"""
        SELECT * FROM school.school_users
        WHERE school_id = %s"""
    rows = await get_query_results(sql, params)
    results = [r for r in rows]
    return results

@router.post("/become_editor")
async def become_editor(school_user: SchoolUser = Depends(current_school_user)):
    """ 
    if school is public 
    1. sign editor terms and conditions
    2. add editor role to school_user
    if school is private
    1. verify editor invitation code
    2. sign editor terms and conditions
    3. add editor role to school_user
    """
    return {}


@router.post("/sign_editor_terms")
async def sign_editor_terms(school_user: SchoolUser = Depends(current_school_user_full)):
    sql = "UPDATE school.school_users SET signed_terms_version = 1 WHERE user_id = %s AND school_id = %s"
    params = (school_user.user_id, school_user.school_id)
    await get_query_results(sql, params)
    return {"message": "Editor terms signed"}   

@router.get("/editor_terms")
async def sign_editor_terms():
    with open("legal/EDITOR_TERMS.txt", "r") as f:
        terms = f.read()
    return {"terms": terms}


