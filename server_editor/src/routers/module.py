from fastapi import HTTPException, Depends, APIRouter
from models.module import Module
from utils.module_utils import (
    create_module, get_module, 
    get_module_full,
    get_course_modules,
    update_module,
    delete_module,
)

router = APIRouter()    

@router.get("/module/full")
async def get_module_full_endpoint(module_id: int):
    return await get_module_full(module_id)

@router.get("/modules")
async def list_modules(course_id: int):
    return await get_course_modules(course_id)
    
@router.get("/module")
async def get_module_endpoint(module_id: int):
    return await get_module(module_id)

@router.post("/module")
async def create_module_endpoint(module: Module):
    return await create_module(module)

@router.put("/module")
async def update_module_endpoint(module: Module) -> Module:
    """Updates a module"""
    return await update_module(module)

@router.delete("/module")
async def delete_module_endpoint(module: Module):
    """Deletes a module"""
    await delete_module(module)
    return {"message": "Module deleted"}
