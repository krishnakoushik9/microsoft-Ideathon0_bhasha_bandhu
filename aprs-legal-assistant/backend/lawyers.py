from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import uuid

class Review(BaseModel):
    reviewer_name: str
    rating: float
    comment: str

class Lawyer(BaseModel):
    id: str
    name: str
    specializations: List[str]
    location: str
    rating: float
    contact_email: str
    contact_phone: str
    reviews: List[Review]

# Model for creating/updating a lawyer (no id)
class LawyerCreate(BaseModel):
    name: str
    specializations: List[str]
    location: str
    rating: float
    contact_email: str
    contact_phone: str
    reviews: List[Review] = []

# Sample data store
lawyers_db: List[Lawyer] = [
    Lawyer(
        id=str(uuid.uuid4()),
        name="Anita Desai",
        specializations=["Family", "Property"],
        location="Mumbai",
        rating=4.7,
        contact_email="anita.desai@lawfirm.com",
        contact_phone="+91-22-12345678",
        reviews=[
            Review(reviewer_name="Rohan", rating=5.0, comment="Very helpful and professional."),
            Review(reviewer_name="Sneha", rating=4.5, comment="Good service but a bit pricey.")
        ]
    ),
    Lawyer(
        id=str(uuid.uuid4()),
        name="Vikram Singh",
        specializations=["Criminal", "Corporate"],
        location="Delhi",
        rating=4.9,
        contact_email="vikram.singh@lawdefense.com",
        contact_phone="+91-11-87654321",
        reviews=[
            Review(reviewer_name="Priya", rating=5.0, comment="Excellent trial lawyer."),
            Review(reviewer_name="Arjun", rating=4.8, comment="Great strategist.")
        ]
    ),
    Lawyer(
        id=str(uuid.uuid4()),
        name="Nina Kapoor",
        specializations=["Corporate", "Property"],
        location="Bengaluru",
        rating=4.6,
        contact_email="nina.kapoor@courtwise.com",
        contact_phone="+91-80-12349876",
        reviews=[
            Review(reviewer_name="Shweta", rating=4.7, comment="Very reliable."),
            Review(reviewer_name="Manish", rating=4.5, comment="Good communication.")
        ]
    )
]

router = APIRouter(prefix="/lawyers", tags=["lawyers"])

@router.get("/", response_model=List[Lawyer])
def get_lawyers(case_type: Optional[str] = Query(None), location: Optional[str] = Query(None)):
    results = lawyers_db
    if case_type:
        results = [l for l in results if case_type in l.specializations]
    if location:
        results = [l for l in results if location.lower() in l.location.lower()]
    return results

# Admin endpoints: create, update, delete
@router.post("/", response_model=Lawyer)
def create_lawyer(lawyer: LawyerCreate):
    new_lawyer = Lawyer(id=str(uuid.uuid4()), **lawyer.dict())
    lawyers_db.append(new_lawyer)
    return new_lawyer

@router.put("/{lawyer_id}", response_model=Lawyer)
def update_lawyer(lawyer_id: str, lawyer: LawyerCreate):
    for idx, l in enumerate(lawyers_db):
        if l.id == lawyer_id:
            updated = Lawyer(id=lawyer_id, **lawyer.dict())
            lawyers_db[idx] = updated
            return updated
    raise HTTPException(status_code=404, detail="Lawyer not found")

@router.delete("/{lawyer_id}")
def delete_lawyer(lawyer_id: str):
    for idx, l in enumerate(lawyers_db):
        if l.id == lawyer_id:
            lawyers_db.pop(idx)
            return {"detail": "Lawyer deleted"}
    raise HTTPException(status_code=404, detail="Lawyer not found")
