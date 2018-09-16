import pyrebase
import datetime



class Storage:



    def __init__(self, \
                 platformsPairName):
        self.__platformsPairName = platformsPairName



    def addDeal(self,
                isForward:bool, \
                amount:float, \
                buyPrice:float, \
                sellPrice:float):
        incomeInPercents = (sellPrice - buyPrice) / buyPrice * 100
        incomeFiat = (sellPrice - buyPrice) * amount

        data = {
            "amount" : "{0:.6f}".format(amount),
            "buyPrice" : str(buyPrice),
            "sellPrice" : str(sellPrice),
            "incomeOrLossInPercents" : str(incomeInPercents),
            "incomeOrLossFiat" : "{0:.2f}".format(incomeFiat)
        }

        nodeName = '{:%Y-%m-%d %H:%M:%S}'.format(datetime.datetime.now())
        if isForward:
            nodeName = "Forward_" + nodeName
        else:
            nodeName = "Reverse_" + nodeName

        db = Storage.__firebase.database()
        db.child(self.__platformsPairName).child(nodeName).set(data)



    # Internal fields

    __config = {
        "apiKey": "apiKey",
        "authDomain": "quicktony-3ebd4.firebaseapp.com",
        "databaseURL": "https://quicktony-3ebd4.firebaseio.com/",
        "storageBucket": "quicktony-3ebd4.appspot.com"
    }

    __firebase = pyrebase.initialize_app(__config)    