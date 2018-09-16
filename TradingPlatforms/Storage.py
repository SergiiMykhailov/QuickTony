import pyrebase
import datetime



class Storage:



    def __init__(self, \
                 platform1Name,
                 platform2Name):
        self.__platform1Name = platform1Name
        self.__platform2Name = platform2Name
        self.__platformsPairName = platform1Name + "__" + platform2Name

        config = {
            "apiKey": "apiKey",
            "authDomain": "quicktony-3ebd4.firebaseapp.com",
            "databaseURL": "https://quicktony-3ebd4.firebaseio.com/",
            "storageBucket": "quicktony-3ebd4.appspot.com"
        }

        firebase = pyrebase.initialize_app(config)
        self.__database = firebase.database()



    def addDeal(self,
                isForward:bool, \
                boughtAt:str, \
                amount:float, \
                buyPrice:float, \
                sellPrice:float):
        assert(boughtAt == self.__platform1Name or boughtAt == self.__platform2Name)

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

        self.__database.child(self.__platformsPairName).child("deals").child(nodeName).set(data)



    def recordTimestamp(self):
        timestamp = '{:%Y-%m-%d %H:%M:%S}'.format(datetime.datetime.now())

        data = {
            "timestamp" : timestamp
        }

        self.__database.child(self.__platformsPairName).child("timestamp").set(data)



    # Internal fields

     