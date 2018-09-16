import pyrebase
import datetime



class Storage:



    @staticmethod
    def addDeal(boughtAtPlatform:str, \
                soldAtPlatfrom:str, \
                amount:float, \
                buyPrice:float, \
                sellPrice:float):
        platformsNode = boughtAtPlatform.lower() + "__" + soldAtPlatfrom.lower()
        db = Storage.__firebase.database()

        date = '{:%Y-%m-%d %H:%M:%S}'.format(datetime.datetime.now())

        data = {
            "amount" : str(amount),
            "boughtAt" : boughtAtPlatform,
            "buyPrice" : str(buyPrice),
            "sellPrice" : str(sellPrice)
        }

        db.child(platformsNode).child(date).set(data)



    # Internal fields

    __config = {
        "apiKey": "apiKey",
        "authDomain": "quicktony-3ebd4.firebaseapp.com",
        "databaseURL": "https://quicktony-3ebd4.firebaseio.com/",
        "storageBucket": "quicktony-3ebd4.appspot.com"
    }

    __firebase = pyrebase.initialize_app(__config)    