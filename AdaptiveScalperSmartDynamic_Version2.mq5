//+------------------------------------------------------------------+
//| Adaptive & Smart Scalping EA for MT5 - Dynamic Signal & Lot      |
//+------------------------------------------------------------------+
#property copyright "AI Copilot"
#property version   "1.40"
#property strict

input double BaseLot        = 0.01;
input int    StopLoss       = 100;
input int    TakeProfit     = 120;
input int    RSI_Period     = 7;
input double RSI_BuyLevel   = 28.0;
input double RSI_SellLevel  = 72.0;
input int    MACD_Fast      = 12;
input int    MACD_Slow      = 26;
input int    MACD_Signal    = 9;
input int    BollPeriod     = 20;
input double BollDev        = 2.0;
input int    MaxLossStreak  = 3;
input int    Slippage       = 5;
input int    MagicNumber    = 20250706;
input double MaxSpread      = 15;
input int    MinBodySize    = 30;
input int    SlowMAPeriod   = 50;
input int    StartHour      = 6;
input int    EndHour        = 22;

double    LotSize;
int       LossStreak = 0;
bool      ReverseMode = false;
int       TotalTrades = 0;
int       WinTrades = 0;
int       LossTrades = 0;

// متغير جديد: أقصى عدد صفقات ديناميكي
int DynamicMaxTrades = 3;

struct TradeResult {
   double profit;
   bool   win;
};
TradeResult tradeHistory[100];
int tradeIndex = 0;

// إضافة نتيجة صفقة
void AddTradeResult(bool win, double profit) {
   tradeHistory[tradeIndex % 100].win = win;
   tradeHistory[tradeIndex % 100].profit = profit;
   tradeIndex++;
   if(win) WinTrades++; else LossTrades++;
   TotalTrades++;
}

// نسبة الفوز
double WinRate() {
   int total = MathMin(tradeIndex,100), wins=0;
   for(int i=0;i<total;i++) if(tradeHistory[i].win) wins++;
   return total>0 ? (double)wins/total : 0.5;
}

// تكييف الاستراتيجية تلقائياً
void AdaptStrategy() {
   if(WinRate() < 0.4 || LossStreak >= MaxLossStreak) {
      LotSize = MathMax(BaseLot/2.0, 0.01);
      ReverseMode = !ReverseMode;
      LossStreak = 0;
   } else {
      LotSize = BaseLot;
      ReverseMode = false;
   }
}

// فلتر السبريد
bool SpreadFilter() {
   double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
   return (spread <= MaxSpread);
}

// فلتر حجم الشمعة السابقة
bool CandleBodyFilter() {
   double open = iOpen(_Symbol, 0, 1);
   double close = iClose(_Symbol, 0, 1);
   double body = MathAbs(close - open) / _Point;
   return (body <= MinBodySize);
}

// فلتر أوقات التداول
bool TimeFilter() {
   int hour = TimeHour(TimeCurrent());
   return (hour >= StartHour && hour < EndHour);
}

// فلتر الموفينج أفريج
bool MovingAverageFilter(bool isBuy) {
   double ma = iMA(_Symbol, 0, SlowMAPeriod, 0, MODE_SMA, PRICE_CLOSE, 0);
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(isBuy)
      return price > ma;
   else
      return price < ma;
}

// حساب اللوت المناسب حسب الرصيد
double CalculateDynamicLot(bool strongSignal) {
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double lot = 0.01;
   if(equity < 50) lot = 0.01; // رصيد صغير جداً
   else if(equity < 100) lot = 0.01;
   else if(equity < 200) lot = 0.02;
   else if(equity < 500) lot = 0.03;
   else lot = 0.05;
   // لو الإشارة قوية جداً، ضاعف اللوت بشكل آمن
   if(strongSignal && equity > 15) lot *= 2.0;
   return NormalizeDouble(lot,2);
}

// تقدير قوة الإشارة (قوية جداً إذا جميع الفلاتر والمؤشرات متوافقة بقوة)
bool IsStrongSignal(bool isBuy, double rsi, double macd_main, double macd_signal, double price, double bb_upper, double bb_lower) {
   if(isBuy) {
      return (rsi < RSI_BuyLevel-10 && price < bb_lower && macd_main > macd_signal+0.2 && MovingAverageFilter(true));
   } else {
      return (rsi > RSI_SellLevel+10 && price > bb_upper && macd_main < macd_signal-0.2 && MovingAverageFilter(false));
   }
}

// الدالة الرئيسية للروبوت
int OnInit() {
   LotSize = BaseLot;
   return(INIT_SUCCEEDED);
}

void OnTick() {
   // الفلاتر الذكية
   if(!SpreadFilter()) return;
   if(!CandleBodyFilter()) return;
   if(!TimeFilter()) return;

   // المؤشرات الفنية
   double rsi = iRSI(NULL, 0, RSI_Period, PRICE_CLOSE, 0);
   double macd_main[], macd_signal[];
   double bb_upper[], bb_lower[];
   if(CopyBuffer(iMACD(NULL,0,MACD_Fast,MACD_Slow,MACD_Signal,PRICE_CLOSE),0,0,2,macd_main)!=2) return;
   if(CopyBuffer(iMACD(NULL,0,MACD_Fast,MACD_Slow,MACD_Signal,PRICE_CLOSE),1,0,2,macd_signal)!=2) return;
   if(CopyBuffer(iBands(NULL,0,BollPeriod,BollDev,0,PRICE_CLOSE),1,0,2,bb_upper)!=2) return;
   if(CopyBuffer(iBands(NULL,0,BollPeriod,BollDev,0,PRICE_CLOSE),2,0,2,bb_lower)!=2) return;

   double price_bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double price_ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);

   // إشارات الدخول
   bool buySignal = false, sellSignal = false;
   bool strongBuy = false, strongSell = false;

   if(!ReverseMode) {
      buySignal  = (rsi < RSI_BuyLevel && price_bid <= bb_lower[0] && macd_main[0] > macd_signal[0] && MovingAverageFilter(true));
      sellSignal = (rsi > RSI_SellLevel && price_bid >= bb_upper[0] && macd_main[0] < macd_signal[0] && MovingAverageFilter(false));
      strongBuy  = IsStrongSignal(true, rsi, macd_main[0], macd_signal[0], price_bid, bb_upper[0], bb_lower[0]);
      strongSell = IsStrongSignal(false, rsi, macd_main[0], macd_signal[0], price_bid, bb_upper[0], bb_lower[0]);
   } else {
      buySignal  = (rsi > RSI_SellLevel && price_bid >= bb_upper[0] && macd_main[0] < macd_signal[0] && MovingAverageFilter(true));
      sellSignal = (rsi < RSI_BuyLevel && price_bid <= bb_lower[0] && macd_main[0] > macd_signal[0] && MovingAverageFilter(false));
      strongBuy  = IsStrongSignal(false, rsi, macd_main[0], macd_signal[0], price_bid, bb_upper[0], bb_lower[0]);
      strongSell = IsStrongSignal(true, rsi, macd_main[0], macd_signal[0], price_bid, bb_upper[0], bb_lower[0]);
   }

   // تحديد عدد الصفقات واللوت بناءً على قوة الإشارة
   if(strongBuy || strongSell) {
      DynamicMaxTrades = 5; // أقصى عدد صفقات في الحالات القوية
      LotSize = CalculateDynamicLot(true);
   } else {
      DynamicMaxTrades = 3; // الإعداد الافتراضي
      LotSize = CalculateDynamicLot(false);
   }

   if(PositionsTotalByMagic(MagicNumber) >= DynamicMaxTrades) return;

   if(buySignal)  OpenOrder(ORDER_TYPE_BUY, price_ask);
   if(sellSignal) OpenOrder(ORDER_TYPE_SELL, price_bid);

   // Trailing Stop
   TrailAllPositions();
}

// فتح صفقة جديدة
void OpenOrder(int type, double price) {
   double sl = (type==ORDER_TYPE_BUY) ? price - StopLoss * _Point : price + StopLoss * _Point;
   double tp = (type==ORDER_TYPE_BUY) ? price + TakeProfit * _Point : price - TakeProfit * _Point;

   MqlTradeRequest req = {};
   req.action = TRADE_ACTION_DEAL;
   req.symbol = _Symbol;
   req.volume = LotSize;
   req.type = type;
   req.price = price;
   req.sl = sl;
   req.tp = tp;
   req.deviation = Slippage;
   req.magic = MagicNumber;

   MqlTradeResult res = {};
   if(OrderSend(req, res)==true && res.retcode==TRADE_RETCODE_DONE) {
      // لا شيء إضافي هنا
   }
}

// تتبع وقف الخسارة المتحرك لجميع الصفقات
void TrailAllPositions() {
   for(int i=0;i<PositionsTotal();i++) {
      if(PositionGetTicket(i)==0) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;
      int type = PositionGetInteger(POSITION_TYPE);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      ulong ticket = PositionGetTicket(i);

      double newSL;
      if(type==POSITION_TYPE_BUY) {
         newSL = SymbolInfoDouble(_Symbol, SYMBOL_BID) - 60*_Point;
         if(newSL > curSL && SymbolInfoDouble(_Symbol, SYMBOL_BID) - openPrice > 70*_Point)
            ModifyPosition(ticket, newSL, tp);
      }
      else if(type==POSITION_TYPE_SELL) {
         newSL = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + 60*_Point;
         if(newSL < curSL && openPrice - SymbolInfoDouble(_Symbol, SYMBOL_ASK) > 70*_Point)
            ModifyPosition(ticket, newSL, tp);
      }
   }
}

// تعديل وقف الخسارة/الهدف
void ModifyPosition(ulong ticket, double sl, double tp) {
   MqlTradeRequest req = {};
   req.action = TRADE_ACTION_SLTP;
   req.position = ticket;
   req.symbol = _Symbol;
   req.sl = sl;
   req.tp = tp;
   MqlTradeResult res = {};
   OrderSend(req, res);
}

// حساب عدد الصفقات المفتوحة لهذا الماجيك
int PositionsTotalByMagic(int magic) {
   int total = 0;
   for(int i=0;i<PositionsTotal();i++) {
      if(PositionGetInteger(POSITION_MAGIC)==magic)
         total++;
   }
   return total;
}

// متابعة نتائج الصفقات (تعمل تلقائياً بعد كل صفقة)
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &req, const MqlTradeResult &res) {
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD && (trans.deal_type==DEAL_TYPE_BUY || trans.deal_type==DEAL_TYPE_SELL)) {
      double profit = trans.profit;
      bool win = (profit > 0.0);
      AddTradeResult(win, profit);
      if(win) LossStreak = 0; else LossStreak++;
      AdaptStrategy();
   }
}