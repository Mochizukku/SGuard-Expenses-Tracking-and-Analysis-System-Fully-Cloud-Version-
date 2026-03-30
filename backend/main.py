# FastAPI Backend for SGuard - Firestore Gateway

## This file is a REFERENCE implementation
## Copy this to your FastAPI backend and run it separately

## Installation Requirements

# ```bash
# pip install fastapi uvicorn firebase-admin python-multipart
# ```

# ## Code: main.py

# ```python
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Initialize Firebase
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

app = FastAPI(title="SGuard Firestore Gateway")

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============ MODELS ============

class UserAccountCreate(BaseModel):
    uid: str
    email: str
    name: str
    balance: float

class UserAccountUpdate(BaseModel):
    name: Optional[str] = None
    balance: Optional[float] = None

class ExpenseCreate(BaseModel):
    userId: str
    category: str
    amount: float
    description: str
    date: str

class ExpenseUpdate(BaseModel):
    category: Optional[str] = None
    amount: Optional[float] = None
    description: Optional[str] = None
    date: Optional[str] = None

# ============ USER ENDPOINTS ============

@app.post("/api/users")
async def save_user(user: UserAccountCreate):
    """Save or update user account"""
    try:
        db.collection("users").document(user.uid).set({
            "email": user.email,
            "name": user.name,
            "balance": user.balance,
            "createdAt": datetime.now().isoformat(),
            "updatedAt": datetime.now().isoformat(),
        }, merge=True)
        return {"success": True, "uid": user.uid}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/users/{user_id}")
async def get_user(user_id: str):
    """Get user account"""
    try:
        doc = db.collection("users").document(user_id).get()
        if doc.exists:
            return {"success": True, "data": doc.to_dict()}
        return {"success": False, "data": None}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/users/{user_id}/balance")
async def update_balance(user_id: str, balance: float):
    """Update user balance"""
    try:
        db.collection("users").document(user_id).update({
            "balance": balance,
            "updatedAt": datetime.now().isoformat(),
        })
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============ EXPENSE ENDPOINTS ============

@app.post("/api/users/{user_id}/expenses")
async def add_expense(user_id: str, expense: ExpenseCreate):
    """Add new expense"""
    try:
        doc_ref = db.collection("users").document(user_id).collection("expenses").add({
            "userId": user_id,
            "category": expense.category,
            "amount": expense.amount,
            "description": expense.description,
            "date": expense.date,
            "createdAt": datetime.now().isoformat(),
        })
        return {"success": True, "expenseId": doc_ref[1].id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/users/{user_id}/expenses")
async def get_expenses(user_id: str):
    """Get all expenses for user"""
    try:
        docs = db.collection("users").document(user_id).collection("expenses").order_by("date", direction=firestore.Query.DESCENDING).stream()
        expenses = []
        for doc in docs:
            expense = doc.to_dict()
            expense["id"] = doc.id
            expenses.append(expense)
        return {"success": True, "data": expenses}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/users/{user_id}/expenses/{expense_id}")
async def get_expense(user_id: str, expense_id: str):
    """Get single expense"""
    try:
        doc = db.collection("users").document(user_id).collection("expenses").document(expense_id).get()
        if doc.exists:
            data = doc.to_dict()
            data["id"] = doc.id
            return {"success": True, "data": data}
        return {"success": False, "data": None}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/users/{user_id}/expenses/{expense_id}")
async def update_expense(user_id: str, expense_id: str, expense: ExpenseUpdate):
    """Update expense"""
    try:
        update_data = expense.dict(exclude_unset=True)
        update_data["updatedAt"] = datetime.now().isoformat()
        db.collection("users").document(user_id).collection("expenses").document(expense_id).update(update_data)
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/users/{user_id}/expenses/{expense_id}")
async def delete_expense(user_id: str, expense_id: str):
    """Delete expense"""
    try:
        db.collection("users").document(user_id).collection("expenses").document(expense_id).delete()
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/users/{user_id}/expenses/by-category/{category}")
async def get_expenses_by_category(user_id: str, category: str):
    """Get expenses by category"""
    try:
        docs = db.collection("users").document(user_id).collection("expenses").where("category", "==", category).order_by("date", direction=firestore.Query.DESCENDING).stream()
        expenses = []
        for doc in docs:
            expense = doc.to_dict()
            expense["id"] = doc.id
            expenses.append(expense)
        return {"success": True, "data": expenses}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/users/{user_id}/expenses/by-date-range")
async def get_expenses_by_date_range(user_id: str, start_date: str, end_date: str):
    """Get expenses by date range"""
    try:
        docs = db.collection("users").document(user_id).collection("expenses").where("date", ">=", start_date).where("date", "<=", end_date).order_by("date", direction=firestore.Query.DESCENDING).stream()
        expenses = []
        for doc in docs:
            expense = doc.to_dict()
            expense["id"] = doc.id
            expenses.append(expense)
        return {"success": True, "data": expenses}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/profile-summary/{user_id}")
async def profile_summary(user_id: str):
    """Get user profile summary with expense statistics"""
    try:
        # Get user data
        user_doc = db.collection("users").document(user_id).get()
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="User not found")
        
        user_data = user_doc.to_dict()
        
        # Get all expenses
        expense_docs = db.collection("users").document(user_id).collection("expenses").stream()
        total_spent = 0
        expenses_count = 0
        
        for doc in expense_docs:
            expense = doc.to_dict()
            total_spent += expense.get("amount", 0)
            expenses_count += 1
        
        return {
            "success": True,
            "data": {
                "user": user_data,
                "totalSpent": total_spent,
                "expenseCount": expenses_count,
                "remainingBalance": user_data.get("balance", 0) - total_spent
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Health check
@app.get("/api/health")
async def health():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
# ```

# ## Setup Instructions

# 1. **Create service account key**:
#    - Go to Firebase Console → Project Settings → Service Accounts
#    - Click "Generate New Private Key"
#    - Save as `serviceAccountKey.json`

# 2. **Install dependencies**:
# ```bash
# pip install fastapi uvicorn firebase-admin python-multipart
# ```

# 3. **Run the server**:
# ```bash
# python main.py
# ```

# 4. **Test the API**:
# ```bash
# curl http://localhost:8000/api/health
# ```

# ## Environment Variables (Optional)

# Create `.env` file:
# ```
# FIREBASE_CREDENTIALS_PATH=serviceAccountKey.json
# API_HOST=0.0.0.0
# API_PORT=8000
# ```

# ## Important Notes

# - This runs on `http://localhost:8000` for development
# - For production, deploy to Google Cloud Run, AWS, or similar
# - Add authentication (JWT tokens) in production
# - Firestore credentials stay on backend (not exposed to Flutter)
# - All Flutter calls go through FastAPI → safer and more controlled
