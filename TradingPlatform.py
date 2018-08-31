from abc import ABC, abstractmethod
import PlatformState


class TradingPlatform(ABC):

    @abstractmethod
    def getState(self) -> PlatformState.PlatformState:
        pass

    @abstractmethod
    def buy(self, price, cryptoAmount):
        pass

    @abstractmethod
    def sell(self, price, cryptoAmount):
        pass