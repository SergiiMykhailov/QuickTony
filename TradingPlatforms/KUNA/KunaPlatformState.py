from .. import PlatformState



class KunaPlatformState(PlatformState.PlatformState):



    def __init__(self, ordersBook, accountInfo, fiatCurrencyRate):
        self.__ordersBook = ordersBook
        self.__accountInfo = accountInfo
        self.fiatCurrencyRate = fiatCurrencyRate



    def getTopBuyOrder(self) -> PlatformState.Order:
        buyOrders = self.__ordersBook['bids']
        
        return self.__getOrderFromItems(buyOrders)

        
        
    def getTopSellOrder(self) -> PlatformState.Order:
        sellOrders = self.__ordersBook['asks']

        return self.__getOrderFromItems(sellOrders)
        
        

    def getAvailableFiatAmount(self) -> float:
        return self.__getAvailableAmount('uah')

        

    def getAvailableCryptoAmount(self) -> float:
        return self.__getAvailableAmount('btc')


        
    def __getOrderFromItems(self, items):
        if len(items) > 0:
            price = float(items[0]['price'])
            cryptoAmount = float(items[0]['remaining_volume'])

            return PlatformState.Order(cryptoAmount, price)

        return None



    def __getAvailableAmount(self, asset):
        accounts = self.__accountInfo['accounts']
        for balanceItem in accounts:
            if balanceItem['currency'] == asset:
                result = float(balanceItem['balance'])
                return result

        return 0.0
