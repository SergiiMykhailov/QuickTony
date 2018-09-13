from . import Trader
from .BTCTrade import BTCTradeUATradingPlatform
from .KUNA import KunaTradingPlatform
import argparse
from enum import Enum



class TraderFactory(object):



    def makeTrader(self):
        parser = argparse.ArgumentParser(description='BTCTradeUA/Kuna/BTC-Alpha automatic trading robot')
        parser.add_argument('platform1', help='1st trading platform. Should be one of: {BTCTrade, KUNA, BTCAlpha}')
        parser.add_argument('platform1PublicKey', help='public key for 1st trading platform')
        parser.add_argument('platform1PrivateKey', help='private key for 1st trading platform')
        parser.add_argument('platform2', help='2nd trading platform. Should be one of: {BTCTrade, KUNA, BTCAlpha}')
        parser.add_argument('platform2PublicKey', help='public key for 2nd trading platform')
        parser.add_argument('platform2PrivateKey', help='private key for 2nd trading platform')

        args = parser.parse_args()

        platform1 = self.__createPlatform(args.platform1, args.platform1PublicKey, args.platform1PrivateKey)
        platform2 = self.__createPlatform(args.platform2, args.platform2PublicKey, args.platform2PrivateKey)

        return Trader.Trader(platform1, platform2)



    def __createPlatform(self, platformName:str, platformPublicKey:str, platformPrivateKey:str):
        platformType = self.__getPlatformTypeFromString(platformName)

        if platformType == TraderFactory.Platform.BTC_TRADE:
            return BTCTradeUATradingPlatform.BTCTradeUATradingPlatform(platformPublicKey, platformPrivateKey)
        elif platformType == TraderFactory.Platform.KUNA:
            return KunaTradingPlatform.KunaTradingPlatform(platformPublicKey, platformPrivateKey)
        elif platformType is None:
            raise ValueError('Unsupported platform: ' + platformName)

        

    def __getPlatformTypeFromString(self, platformName:str) -> None:
        platformNameLower = platformName.lower()

        if platformNameLower == 'btctrade':
            return TraderFactory.Platform.BTC_TRADE
        elif platformNameLower == 'kuna':
            return TraderFactory.Platform.KUNA
        elif platformNameLower == 'btcalpha':
            return TraderFactory.Platform.BTC_ALPHA

        return None



    class Platform(Enum):
        BTC_TRADE = 1
        KUNA = 2
        BTC_ALPHA = 3