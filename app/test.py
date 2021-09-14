import unittest
import configparser

from services.connexion import *
class TestStringMethods(unittest.TestCase):
    def testuser(self):
        if session.query(Utilisateur).filter_by(mail = "hmfonzie@yahoo.com", motdepass ="root").first() != None:
            test = True
        else:
            test = False
        self.assertTrue(test)

if __name__ == '__main__':
    unittest.main()
