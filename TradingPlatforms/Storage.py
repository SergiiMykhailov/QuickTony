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
            nodeName = nodeName + "_forward_from_" + boughtAt
        else:
            nodeName = nodeName + "_reverse_from_" + boughtAt

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




    def getMinForwardRatio(self):
        node = self.__getRootNode().child("min_forward_ratio")
        result = self.__getValueOrNoneForNode(node)

        return result



    def getMaxLossRatio(self):
        node = self.__getRootNode().child("max_loss_ratio")
        result = self.__getValueOrNoneForNode(node)

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
        node = self.__getRootNode().child(nodeName)
        result = self.__getValueOrNoneForNode(node)

        return result



    def __adjustAmountToReturn(self, adjustAmount, isForPlatform1):
        updatedValue = self.getAmountToReturn(isForPlatform1)
        if updatedValue is None:
            updatedValue = 0.0

        updatedValue += adjustAmount

        nodeName = self.__getReturnFromNodeName(isForPlatform1)

        data = {
            nodeName : "{0:.6f}".format(updatedValue)
        }

        self.__getRootNode().update(data)



    def __updateAmountToReturn(self, amount, isForward, isFromPlatform1Platform2):
        if isForward == True:
            self.__adjustAmountToReturn(amount, isFromPlatform1Platform2)
        else:
            self.__adjustAmountToReturn(-amount, isFromPlatform1Platform2)



    def __getValueOrNoneForNode(self, node):
        result = None

        response = node.get()
        if response.pyres is not None:
            result = float(response.pyres)

        return result