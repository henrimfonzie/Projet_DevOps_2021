
from sqlalchemy.orm import session
from models.models import *


def getUserBtLoginAndPwd(login, pwd):
    return session.query(Utilisateur).filter_by(mail = login, motdepass = pwd).first()

def createUser(newUser):
    if newUser != None:
        session.add(newUser)
        session.commit()