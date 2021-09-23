import unittest

from services.connexion import *
class TestStringMethods(unittest.TestCase):
    
    def database_co(self):
        if session.query(Utilisateur).filter_by(mail = "admin", motdepass ="root").first() != None:
            test = True
        else:
            test = False
        self.assertTrue(test)
    def testuser(self):
        if session.query(Utilisateur).filter_by(mail = "admin", motdepass ="root").first() != None:
            test = True
        else:
            test = False
        self.assertTrue(test)
if __name__ == '__main__':
    unittest.main()
