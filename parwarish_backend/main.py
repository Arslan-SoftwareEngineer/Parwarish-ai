from fastapi import FastAPI, HTTPException
import firebase_admin
from firebase_admin import credentials, firestore
from pydantic import BaseModel
from typing import List

# Initialize FastAPI
app = FastAPI(title="Parwarish.ai Backend")

# Initialize Firebase Admin
cred = credentials.Certificate("firebase_credentials.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# --- Pydantic Models ---
class ParentProfile(BaseModel):
    parent_id: str
    name: str
    email: str

# --- API Endpoints ---
@app.get("/")
def read_root():
    return {"message": "Welcome to the Parwarish.ai API"}

@app.post("/parents/register")
def register_parent(parent: ParentProfile):
    try:
        # Save parent to Firestore
        doc_ref = db.collection("parents").document(parent.parent_id)
        doc_ref.set({
            "name": parent.name,
            "email": parent.email,
            "linked_children": [],
            "verified_status": False
        })
        return {"status": "success", "message": f"Parent {parent.name} registered successfully."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class LinkChildRequest(BaseModel):
    parent_id: str
    child_id: str

@app.post("/parents/link-child")
def link_child_to_parent(request: LinkChildRequest):
    try:
        # 1. Verify the child exists
        child_ref = db.collection("children").document(request.child_id)
        child_doc = child_ref.get()
        
        if not child_doc.exists:
            raise HTTPException(status_code=404, detail="Child ID not found.")
            
        # 2. Update the child's profile with the parent's ID
        child_ref.update({
            "parent_id": request.parent_id
        })
        
        # 3. Add the child ID to the parent's linked_children array
        parent_ref = db.collection("parents").document(request.parent_id)
        parent_ref.update({
            # ArrayUnion ensures we don't add duplicates if they click twice
            "linked_children": firestore.ArrayUnion([request.child_id])
        })
        
        return {
            "status": "success", 
            "message": f"Child {request.child_id} successfully linked."
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))