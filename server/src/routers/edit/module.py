from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from utils.auth_deps import current_school_user, current_school_user_full
from utils.db import get_query_results
from models.auth import SchoolUser
from models.edit.module  import ModuleEdit
router = APIRouter()

@router.post("/")
async def create_module(    
    module: ModuleEdit,
    school_user: SchoolUser = Depends(current_school_user_full)
):
    sql = f""" 
       INSERT INTO course_simple.module 
       (course_id, title, description, words)
         VALUES(%s, %s, %s, %s)
         returning module_id
    """
    params = (
        module.course_id,
        module.title,
        module.description,
        module.words
    )
    try:
        data = await get_query_results(sql, params)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    try:
        module_id = data[0]['module_id']
        module.module_id = module_id
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to retrieve module_id from the database response.")

    return module       

@router.get("/{course_id}")
async def get_modules(
    course_id: int,
    school_user: SchoolUser = Depends(current_school_user_full)
):
    sql = """
        SELECT * FROM course_simple.module
        WHERE course_id = %s
    """
    params = (course_id,)
    try:
        modules = await get_query_results(sql, params)
        return modules
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 

@router.put("/{module_id}")
async def update_module(
    module_id: int,
    module: ModuleEdit,
    school_user: SchoolUser = Depends(current_school_user_full)
):
    sql = f"""
        UPDATE course_simple.module
        SET title = %s, description = %s, words = %s
        WHERE module_id = %s
        returning module_id
    """
    params = (
        module.title,
        module.description,
        module.words,
        module_id
    )
    try:
        data = await get_query_results(sql, params)
        if not data:
            raise HTTPException(status_code=404, detail="Module not found")
        return {"message": "Module updated successfully", "module_id": data[0]['module_id']}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))     


@router.delete("/{module_id}")
async def delete_module(
    module_id: int,
    school_user: SchoolUser = Depends(current_school_user_full)
):
    sql = f"""
        DELETE FROM course_simple.module
        WHERE module_id = %s
    """
    params = (module_id,)
    try:
        await get_query_results(sql, params)
        return {"message": "Module deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 
