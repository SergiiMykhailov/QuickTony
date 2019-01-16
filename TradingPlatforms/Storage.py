import pyrebase
import datetime



class Storage:



    def __init__(self, \
                 platform1Name,
                 platform2Name):
        self.__platform1Name = platform1Name
        self.__platform2Name = platform2Name
        self.__platformsPairName = platform1Name.lower() + "__" + platform2Name.lower()

        config = {
            "apiKey": "apiKey",
            "authDomain": "quicktony-3ebd4.firebaseapp.com",
            "databaseURL": "https://quicktony-3ebd4.firebaseio.com/",
            "storageBucket": "quicktony-3ebd4.appspot.com"
        }

        firebase = pyrebase.initialize_app(config)
        self.__database = firebase.database()



    def storeDeal(self,
                  isForward:bool, \
                  isFromPlatform1Platform2:bool, \
                  amount:float, \
                  buyPrice:float, \
                  sellPrice:float):
        incomeInPercents = (sellPrice - buyPrice) / buyPrice * 100
        incomeFiat = (sellPrice - buyPrice) * amount

        data = {
            "amount" : "{0:.6f}".format(amount),
            "buyPrice" : str(buyPrice),
            "sellPrice" : str(sellPrice),
            "incomeOrLossInPercents" : "{0:.2f}".format(incomeInPercents),
            "incomeOrLossFiat" : "{0:.2f}".format(incomeFiat)
        }

        nodeName = '{:%Y-%m-%d %H:%M:%S}'.format(datetime.datetime.now())
        boughtAt = self.__platform1Name
        if isFromPlatform1Platform2 == False:
            boughtAt = self.__platform2Name

        if isForward:
            nodeName = "forward_from_" + boughtAt + "_" + nodeName
        else:
            nodeName = "reverse_from_" + boughtAt + "_" + nodeName

        self.__getRootNode().child("deals").child(nodeName).set(data)

        self.__updateAmountToReturn(amount, isForward, isFromPlatform1Platform2)



    def recordTimestamp(self):
        timestamp = '{:%Y-%m-%d %H:%M:%S}'.format(datetime.datetime.now())

        data = {
            "timestamp" : timestamp
        }

        self.__getRootNode().child("timestamp").set(data)



    def getAmountToReturn(self, isFromPlatform1):
        result = self.__getAmountToReturn(self.__getReturnFromNodeName(isFromPlatform1))
        return result



    # Internal methods

    
    
    def __getReturnFromNodeName(self, isForPlatform1):
        result = "returnFrom_"

        if isForPlatform1:
            result += self.__platform1Name.lower()
        else:
            result += self.__platform2Name.lower()

        return result



    def __getRootNode(self):
        return self.__database.child(self.__platformsPairName)



    def __getAmountToReturn(self, nodeName):
        result = 0.0

        response = self.__getRootNode().child(nodeName).get()
        if response.pyres is not None:
            result = float(response.pyres[0].item[1])

        return result



    def __adjustAmountToReturn(self, adjustAmount, isForPlatform1):
        updatedValue = 0.0

        if isForPlatform1 == True:
            self.__returnFromPlatform1 += adjustAmount
            updatedValue = self.__returnFromPlatform1
        else:
            self.__returnFromPlatform2 += adjustAmount
            updatedValue = self.__returnFromPlatform2

        nodeName = self.__getReturnFromNodeName(isForPlatform1)

        data = {
            "amount" : "{0:.6f}".format(updatedValue)
        }

        self.__getRootNode().child(nodeName).set(data)



    def __updateAmountToReturn(self, amount, isForward, isFromPlatform1Platform2):
        if isForward == True:
            self.__adjustAmountToReturn(amount, isFromPlatform1Platform2)
        else:
            self.__adjustAmountToReturn(-amount, isFromPlatform1Platform2)