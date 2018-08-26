import Trader
import argparse

parser = argparse.ArgumentParser(description='BTCTradeUA/Kuna automatic trading robot')
parser.add_argument('btcTradeUAPublicKey', help='public key for btc-trade.com.ua')
parser.add_argument('btcTradeUAPrivateKey', help='private key for btc-trade.com.ua')
parser.add_argument('kunaPublicKey', help='public key for kuna.io')
parser.add_argument('kunaPrivateKey', help='private key for kuna.io')

args = parser.parse_args()

trader = Trader.Trader(args.btcTradeUAPublicKey, args.btcTradeUAPrivateKey, args.kunaPublicKey, args.kunaPrivateKey)
trader.run()