from fastapi import HTTPException, Depends, APIRouter
from models.module import Module
router = APIRouter()    

@router.get("/modules")
async def list_modules(course_id: int):
    return {"message": f"List of modules for course {course_id}"}

@router.get("/module")
async def get_module(module_id: int):
    return {"message": f"Details of module {module_id}"}

@router.post("/module")
async def create_module(module: Module):
    return {"message": "Module created"}

@router.put("/module")
async def update_module(module: Module) -> Module:
    """Updates a module"""
    return module

@router.delete("/module")
async def delete_module(module: Module):
    """Deletes a module"""
    return {"message": "Module deleted"}
