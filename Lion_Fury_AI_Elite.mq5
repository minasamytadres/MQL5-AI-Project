//+------------------------------------------------------------------+
//|                                           Lion_Fury_AI_Elite.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "7.1"
#property description "Lion's Fury AI Elite - Advanced Neural Network Trading System"
#property description "Features: AI-Powered Analysis, Neural Networks, Market Microstructure,"
#property description "Advanced Risk Management, Multi-Timeframe Fusion, Smart Money Concepts"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//------------------------------------------------------------------
//  GLOBAL OBJECTS & VARIABLES                                       |
//------------------------------------------------------------------
CTrade        trade;
CPositionInfo position;
COrderInfo    order;

//--- AI Neural Network Variables
static double neural_weights[10][10];
static double market_memory[100];
static double ai_confidence    = 0.0;
static double profit_optimizer = 1.0;

//--- Advanced Analysis Variables
static double liquidity_score  = 0.0;
static double momentum_score   = 0.0;
static double volatility_score = 0.0;
static double trend_strength   = 0.0;
static double market_regime    = 0.0;  // 0=Bullish, 1=Bearish, 2=Sideways

//--- Multi-Time-Frame analysis
static ENUM_TIMEFRAMES timeframe_array[] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4};
static double          mtf_signals[5];

//--- Smart Money Concepts
static double order_blocks[10][3];  // [price, volume, time]
static double liquidity_levels[20];
static int    ob_count = 0, liq_count = 0;

//--- Advanced Risk Management
static double dynamic_risk       = 1.0;
static double market_volatility  = 0.0;
static double correlation_factor = 0.0;

//--- Profit Optimisation
static const double profit_targets[5]       = {0.5, 1.0, 2.0, 3.0, 5.0};
static const double partial_close_levels[5] = {25, 50, 75, 90, 100};
static double       trailing_optimizer      = 1.0;

//------------------------------------------------------------------
//  INPUT PARAMETERS                                                 |
//------------------------------------------------------------------
input group "=== AI ELITE CORE SETTINGS ==="
input ENUM_TIMEFRAMES InpMainTimeframe     = PERIOD_M5;   // Main Analysis Timeframe
input ENUM_TIMEFRAMES InpTrendTimeframe    = PERIOD_M15;  // Trend Analysis
input ENUM_TIMEFRAMES InpHigherTimeframe   = PERIOD_H1;   // Higher Confirmation
input ENUM_TIMEFRAMES InpUltraTimeframe    = PERIOD_M1;   // Ultra-Fast Signals

input group "=== AI NEURAL NETWORK SETTINGS ==="
input int    InpNeuralLayers          = 3;     // Neural Network Layers
input int    InpMemorySize            = 100;   // Market Memory Size
input double InpLearningRate          = 0.01;  // AI Learning Rate
input double InpConfidenceThreshold   = 0.75;  // Minimum AI Confidence

input group "=== ADVANCED INDICATOR SETTINGS ==="
input int    InpMA_Fast               = 8;     // Fast MA Period
input int    InpMA_Slow               = 21;    // Slow MA Period
input int    InpMA_Trend              = 50;    // Trend MA Period
input int    InpADX_Period            = 14;    // ADX Period
input int    InpRSI_Period            = 14;    // RSI Period
input int    InpBB_Period             = 20;    // Bollinger Bands Period
input double InpBB_Deviation          = 2.0;   // BB Standard Deviation
input int    InpATR_Period            = 14;    // ATR Period

input group "=== ULTRA INTELLIGENT RISK MANAGEMENT ==="
input double InpBaseRiskPerTrade      = 1.0;   // Base Risk Per Trade (%)
input double InpMaxRiskPerTrade       = 3.0;   // Maximum Risk Per Trade (%)
input double InpDynamicRiskMultiplier = 1.5;   // Dynamic Risk Multiplier
input double InpVolatilityAdjustment  = 0.5;   // Volatility Adjustment
input double InpCorrelationThreshold  = 0.7;   // Correlation Threshold

input group "=== AI PROFIT OPTIMIZATION ==="
input double InpATR_StopLoss_Factor   = 2.0;   // ATR Stop Loss Factor
input double InpTakeProfit_RR_Ratio   = 2.5;   // Take Profit Risk:Reward
input double InpPartialClose_Level1   = 25.0;  // Partial Close Level 1 (%)
input double InpPartialClose_Level2   = 50.0;  // Partial Close Level 2 (%)
input double InpPartialClose_Level3   = 75.0;  // Partial Close Level 3 (%)
input double InpTrailingStart         = 50;    // Trailing Stop Start (pips)
input double InpTrailingDistance      = 30;    // Trailing Stop Distance (pips)
input double InpBreakevenTrigger      = 25;    // Breakeven Trigger (pips)

input group "=== SMART MONEY CONCEPTS ==="
input bool   InpUseOrderBlocks        = true;  // Use Order Blocks
input bool   InpUseLiquidityLevels    = true;  // Use Liquidity Levels
input bool   InpUseMarketStructure    = true;  // Use Market Structure
input int    InpOrderBlockLookback    = 50;    // Order Block Lookback
input int    InpLiquidityLookback     = 100;   // Liquidity Level Lookback

input group "=== AI MARKET REGIME DETECTION ==="
input bool   InpUseMarketRegime       = true;  // Use Market Regime Detection
input bool   InpUseVolatilityRegime   = true;  // Use Volatility Regime
input bool   InpUseCorrelationAnalysis= true;  // Use Correlation Analysis
input int    InpRegimePeriod          = 20;    // Regime Detection Period

input group "=== ULTRA ADVANCED FILTERS ==="
input bool   InpUseNewsFilter         = true;  // Use News Filter
input bool   InpUseTimeFilter         = true;  // Use Time Filter
input bool   InpUseSpreadFilter       = true;  // Use Spread Filter
input double InpMaxSpread             = 3.0;   // Maximum Spread (pips)
input int    InpMinVolume             = 100;   // Minimum Volume

input group "=== AI ELITE SPECIAL FEATURES ==="
input bool   InpUseGridScalping       = true;  // Use Grid Scalping
input bool   InpUseMartingale         = false; // Use Martingale (DANGER!)
input bool   InpUseAntiMartingale     = true;  // Use Anti-Martingale
input int    InpGridLevels            = 3;     // Grid Levels
input double InpGridDistance          = 20;    // Grid Distance (pips)

//------------------------------------------------------------------
//  INDICATOR HANDLES                                                |
//------------------------------------------------------------------
int h_ma_fast, h_ma_slow, h_ma_trend;
int h_adx, h_rsi, h_bb, h_atr;

//------------------------------------------------------------------
//  UTILITY FUNCTIONS                                                |
//------------------------------------------------------------------
// Check terminal trading permission
bool IsTradingAllowed()
{
   return (bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
}

//------------------------------------------------------------------
//  NEURAL NETWORK FUNCTIONS                                         |
//------------------------------------------------------------------
void InitializeNeuralNetwork()
{
   for(int i=0;i<10;i++)
      for(int j=0;j<10;j++)
         neural_weights[i][j]=MathRand()/32768.0-0.5;

   ArrayInitialize(market_memory,0.0);
   Print("🧠 AI Neural Network Initialized");
}

double CalculateNeuralOutput(double &inputs[])
{
   double output=0.0;
   for(int i=0;i<10;i++)
      for(int j=0;j<10;j++)
         output+=inputs[i]*neural_weights[i][j];

   return 1.0/(1.0+MathExp(-output)); // Sigmoid activation
}

void UpdateNeuralNetwork(double actual_result)
{
   for(int i=0;i<10;i++)
      for(int j=0;j<10;j++)
         neural_weights[i][j]+=InpLearningRate*(actual_result-neural_weights[i][j]);
}

//------------------------------------------------------------------
//  ADVANCED MARKET ANALYSIS                                         |
//------------------------------------------------------------------

double CalculateMarketRegime()
{
   double regime_score=0.0;
   for(int i=0;i<5;i++)
   {
      double ma_fast[1],ma_slow[1];
      if(CopyBuffer(h_ma_fast,0,1,1,ma_fast)>0 &&
         CopyBuffer(h_ma_slow,0,1,1,ma_slow)>0)
         regime_score+=(ma_fast[0]>ma_slow[0]?0.2:-0.2);
   }
   if(regime_score>0.3)      return 0.0; // Bullish
   else if(regime_score<-0.3) return 1.0; // Bearish
   return 2.0;                            // Sideways
}

double CalculateVolatilityRegime()
{
   double atr_array[1];
   if(CopyBuffer(h_atr,0,1,1,atr_array)>0)
   {
      double current_atr=atr_array[0];
      double avg_atr=0.0;
      for(int i=1;i<=InpRegimePeriod;i++)
      {
         double atr_tmp[1];
         if(CopyBuffer(h_atr,0,i,1,atr_tmp)>0)
            avg_atr+=atr_tmp[0];
      }
      avg_atr/=InpRegimePeriod;
      if(current_atr<avg_atr*0.8)      return 0.0; // Low
      else if(current_atr>avg_atr*1.2) return 2.0; // High
      return 1.0;                                   // Medium
   }
   return 1.0;
}

//------------------------------------------------------------------
//  SMART MONEY CONCEPTS                                             |
//------------------------------------------------------------------
void DetectOrderBlocks()
{
   ob_count=0;
   for(int i=1;i<InpOrderBlockLookback;i++)
   {
      double high[1],low[1],close[1];
      long   volume[1];
      if(CopyHigh(_Symbol,PERIOD_CURRENT,i,1,high)>0 &&
         CopyLow(_Symbol,PERIOD_CURRENT,i,1,low)>0 &&
         CopyClose(_Symbol,PERIOD_CURRENT,i,1,close)>0 &&
         CopyTickVolume(_Symbol,PERIOD_CURRENT,i,1,volume)>0)
      {
         // Bullish order block
         if(close[0]>high[0] && volume[0]>InpMinVolume)
         {
            if(ob_count<10)
            {
               order_blocks[ob_count][0]=low[0];
               order_blocks[ob_count][1]=(double)volume[0];
               order_blocks[ob_count][2]=(double)i;
               ob_count++;
            }
         }
         // Bearish order block
         else if(close[0]<low[0] && volume[0]>InpMinVolume)
         {
            if(ob_count<10)
            {
               order_blocks[ob_count][0]=high[0];
               order_blocks[ob_count][1]=(double)volume[0];
               order_blocks[ob_count][2]=(double)i;
               ob_count++;
            }
         }
      }
   }
}

void DetectLiquidityLevels()
{
   liq_count=0;
   for(int i=1;i<InpLiquidityLookback;i++)
   {
      double high[1],low[1];
      long   volume[1];
      if(CopyHigh(_Symbol,PERIOD_CURRENT,i,1,high)>0 &&
         CopyLow(_Symbol,PERIOD_CURRENT,i,1,low)>0 &&
         CopyTickVolume(_Symbol,PERIOD_CURRENT,i,1,volume)>0)
      {
         if(volume[0]>InpMinVolume*2)
         {
            if(liq_count<20)
               liquidity_levels[liq_count++]=(high[0]+low[0])/2.0;
         }
      }
   }
}

//------------------------------------------------------------------
//  ULTRA INTELLIGENT SIGNAL GENERATION                              |
//------------------------------------------------------------------
int GetAISignal()
{
   double inputs[10];
   double ma_fast[1],ma_slow[1],adx[1],rsi[1],bb_upper[1],bb_lower[1],atr[1];

   if(CopyBuffer(h_ma_fast,0,1,1,ma_fast)<1 ||
      CopyBuffer(h_ma_slow,0,1,1,ma_slow)<1 ||
      CopyBuffer(h_adx    ,0,1,1,adx    )<1 ||
      CopyBuffer(h_rsi    ,0,1,1,rsi    )<1 ||
      CopyBuffer(h_bb     ,1,1,1,bb_upper)<1 ||
      CopyBuffer(h_bb     ,2,1,1,bb_lower)<1 ||
      CopyBuffer(h_atr    ,0,1,1,atr    )<1)
      return 0;

   inputs[0]=(ma_fast[0]>ma_slow[0]?1.0:-1.0);
   inputs[1]=(adx[0]>25?1.0:0.0);
   inputs[2]=(rsi[0]<30?1.0:(rsi[0]>70?-1.0:0.0));
   inputs[3]=market_regime;
   inputs[4]=CalculateVolatilityRegime();
   inputs[5]=liquidity_score;
   inputs[6]=momentum_score;
   inputs[7]=volatility_score;
   inputs[8]=trend_strength;
   inputs[9]=ai_confidence;

   double neural_output=CalculateNeuralOutput(inputs);
   ai_confidence=neural_output;

   if(neural_output>InpConfidenceThreshold)               return 1;
   else if(neural_output<(1.0-InpConfidenceThreshold))    return -1;
   return 0;
}

//------------------------------------------------------------------
//  DYNAMIC RISK MANAGEMENT                                          |
//------------------------------------------------------------------

double CalculateDynamicRisk()
{
   double risk=InpBaseRiskPerTrade;
   if(market_regime==0.0)      risk*=1.2;
   else if(market_regime==1.0) risk*=0.8;

   double vol_regime=CalculateVolatilityRegime();
   if(vol_regime==0.0)      risk*=1.3;
   else if(vol_regime==2.0) risk*=0.7;

   risk*=ai_confidence;
   if(risk>InpMaxRiskPerTrade) risk=InpMaxRiskPerTrade;
   if(risk<0.1)                risk=0.1;
   return risk;
}

//------------------------------------------------------------------
//  POSITION MANAGEMENT                                              |
//------------------------------------------------------------------
void ManageAIPositions()
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!PositionSelectByTicket(PositionGetTicket(i)))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;

      double pos_profit=PositionGetDouble(POSITION_PROFIT);
      double pos_volume=PositionGetDouble(POSITION_VOLUME);
      ENUM_POSITION_TYPE pos_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      // Partial close
      if(pos_profit>10 && ai_confidence>0.8)
      {
         double close_vol=pos_volume*0.3;
         trade.PositionClosePartial(PositionGetTicket(i),close_vol);
         Print("🤖 AI Partial Close: ",close_vol," lots");
      }

      double current_price=(pos_type==POSITION_TYPE_BUY)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double stop_loss   = PositionGetDouble(POSITION_SL);
      double atr_val[1];
      if(CopyBuffer(h_atr,0,1,1,atr_val)>0)
      {
         double trailing_dist=atr_val[0]*InpATR_StopLoss_Factor*trailing_optimizer;
         if(pos_type==POSITION_TYPE_BUY)
         {
            double new_sl=current_price-trailing_dist;
            if(new_sl>stop_loss && new_sl<current_price)
               trade.PositionModify(PositionGetTicket(i),new_sl,0);
         }
         else
         {
            double new_sl=current_price+trailing_dist;
            if(new_sl<stop_loss && new_sl>current_price)
               trade.PositionModify(PositionGetTicket(i),new_sl,0);
         }
      }
   }
}

//------------------------------------------------------------------
//  TRADE EXECUTION                                                  |
//------------------------------------------------------------------
void ExecuteAITrade(int signal)
{
   if(signal==0) return;
   if(!IsTradingAllowed()) return;

   double risk_percent=CalculateDynamicRisk();
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);

   double atr_arr[1];
   if(CopyBuffer(h_atr,0,1,1,atr_arr)<1) return;
   double atr_val=atr_arr[0];
   double sl_dist=atr_val*InpATR_StopLoss_Factor;
   double tp_dist=sl_dist*InpTakeProfit_RR_Ratio;

   double balance=AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_amt=balance*risk_percent/100.0;
   double lot= risk_amt/(sl_dist*SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE));

   double min_lot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double max_lot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double lot_step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);

   lot=MathMax(min_lot,MathMin(max_lot,lot));
   lot=MathRound(lot/lot_step)*lot_step;

   if(signal==1)
   {
      double sl=ask-sl_dist;
      double tp=ask+tp_dist;
      if(trade.Buy(lot,_Symbol,ask,sl,tp,"AI Elite Buy"))
      {
         Print("🚀 AI Elite BUY: ",lot," lots at ",ask);
         Print("🧠 AI Confidence: ",ai_confidence);
      }
   }
   else if(signal==-1)
   {
      double sl=bid+sl_dist;
      double tp=bid-tp_dist;
      if(trade.Sell(lot,_Symbol,bid,sl,tp,"AI Elite Sell"))
      {
         Print("🚀 AI Elite SELL: ",lot," lots at ",bid);
         Print("🧠 AI Confidence: ",ai_confidence);
      }
   }
}

//------------------------------------------------------------------
//  MULTI-TIMEFRAME & CORRELATION                                    |
//------------------------------------------------------------------
void CalculateMultiTimeframeSignals()
{
   for(int i=0;i<5;i++)
   {
      double ma_f[1],ma_s[1];
      int handle_f=iMA(_Symbol,timeframe_array[i],InpMA_Fast,0,MODE_EMA,PRICE_CLOSE);
      int handle_s=iMA(_Symbol,timeframe_array[i],InpMA_Slow,0,MODE_EMA,PRICE_CLOSE);
      if(CopyBuffer(handle_f,0,1,1,ma_f)>0 && CopyBuffer(handle_s,0,1,1,ma_s)>0)
         mtf_signals[i]=(ma_f[0]>ma_s[0]?1.0:-1.0);
      IndicatorRelease(handle_f);
      IndicatorRelease(handle_s);
   }
}

double CalculateCorrelationFactor()
{
   string majors[]={"EURUSD","GBPUSD","USDJPY","USDCHF"};
   double sum=0.0;int cnt=0;
   for(int i=0;i<ArraySize(majors);i++)
   {
      if(majors[i]==_Symbol) continue;
      double price_other=SymbolInfoDouble(majors[i],SYMBOL_BID);
      double price_self =SymbolInfoDouble(_Symbol   ,SYMBOL_BID);
      if(price_other>0)
      { sum+=MathAbs(price_self-price_other)/price_other; cnt++; }
   }
   return (cnt>0?sum/cnt:0.0);
}

//------------------------------------------------------------------
//  FILTERS                                                         |
//------------------------------------------------------------------
bool CheckNewsFilter()
{
   if(!InpUseNewsFilter) return true;
   MqlDateTime dt;TimeToStruct(TimeCurrent(),dt);
   if(dt.hour==8 || dt.hour==14 || dt.hour==20) return false;
   return true;
}

bool CheckTimeFilter()
{
   if(!InpUseTimeFilter) return true;
   MqlDateTime dt;TimeToStruct(TimeCurrent(),dt);
   if(dt.day_of_week==0 || dt.day_of_week==6) return false;
   if(dt.hour<2 || dt.hour>22)               return false;
   return true;
}

bool CheckSpreadFilter()
{
   if(!InpUseSpreadFilter) return true;
   long spr=SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);
   return (spr<=InpMaxSpread*10);
}

//------------------------------------------------------------------
//  GRID & MARTINGALE                                               |
//------------------------------------------------------------------
void ExecuteGridTrade(int direction)
{
   if(!InpUseGridScalping) return;
   double grid_price=(direction==1)?SymbolInfoDouble(_Symbol,SYMBOL_ASK):SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double lot=0.01;
   for(int i=0;i<InpGridLevels;i++)
   {
      double level_price=grid_price+direction*InpGridDistance*_Point*(i+1);
      if(direction==1)
         trade.Buy(lot,_Symbol,level_price,0,0,"Grid Buy "+IntegerToString(i));
      else
         trade.Sell(lot,_Symbol,level_price,0,0,"Grid Sell "+IntegerToString(i));
   }
}

double CalculateAntiMartingaleLotSize(double base_lot,int consecutive_wins)
{
   return (!InpUseAntiMartingale)?base_lot:base_lot*(1.0+consecutive_wins*0.1);
}

//------------------------------------------------------------------
//  SIGNAL VALIDATION & STRUCTURE                                   |
//------------------------------------------------------------------
bool ValidateSignal(int signal)
{
   if(!CheckNewsFilter() || !CheckTimeFilter() || !CheckSpreadFilter()) return false;
   if(market_regime==2.0 && MathAbs(signal)==1)                        return false;
   correlation_factor=CalculateCorrelationFactor();
   if(correlation_factor>InpCorrelationThreshold)                     return false;
   if(ai_confidence<InpConfidenceThreshold)                           return false;
   return true;
}

void ApplyBreakevenStop()
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!PositionSelectByTicket(PositionGetTicket(i))) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)   continue;
      double open_price=PositionGetDouble(POSITION_PRICE_OPEN);
      double cur_price=(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double profit_pips=MathAbs(cur_price-open_price)/_Point;
      if(profit_pips>=InpBreakevenTrigger && PositionGetDouble(POSITION_PROFIT)>0)
      {
         trade.PositionModify(PositionGetTicket(i),open_price,0);
         Print("🎯 Breakeven Stop Applied");
      }
   }
}

bool IsMarketStructureValid(int signal)
{
   if(!InpUseMarketStructure) return true;
   double ma_tr[1];
   if(CopyBuffer(h_ma_trend,0,1,1,ma_tr)<1) return true;
   double cur_price=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if(signal==1 && cur_price<ma_tr[0])  return false;
   if(signal==-1&& cur_price>ma_tr[0])  return false;
   return true;
}

//------------------------------------------------------------------
//  EXPERT INITIALISATION                                            |
//------------------------------------------------------------------
int OnInit()
{
   trade.SetExpertMagicNumber(123456);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_FOK);

   h_ma_fast=iMA(_Symbol,InpMainTimeframe,InpMA_Fast,0,MODE_EMA,PRICE_CLOSE);
   h_ma_slow=iMA(_Symbol,InpMainTimeframe,InpMA_Slow,0,MODE_EMA,PRICE_CLOSE);
   h_ma_trend=iMA(_Symbol,InpTrendTimeframe,InpMA_Trend,0,MODE_SMA,PRICE_CLOSE);
   h_adx=iADX(_Symbol,InpMainTimeframe,InpADX_Period);
   h_rsi=iRSI(_Symbol,InpMainTimeframe,InpRSI_Period,PRICE_CLOSE);
   h_bb =iBands(_Symbol,InpMainTimeframe,InpBB_Period,0,InpBB_Deviation,PRICE_CLOSE);
   h_atr=iATR(_Symbol,InpMainTimeframe,InpATR_Period);

   if(h_ma_fast==INVALID_HANDLE||h_ma_slow==INVALID_HANDLE||h_adx==INVALID_HANDLE||
      h_rsi==INVALID_HANDLE||h_bb==INVALID_HANDLE||h_atr==INVALID_HANDLE)
   {
      Print("❌ Failed to create indicator handles");
      return INIT_FAILED;
   }

   InitializeNeuralNetwork();
   Print("🤖 Lion's Fury AI Elite v7.1 Initialized");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(h_ma_fast!=INVALID_HANDLE) IndicatorRelease(h_ma_fast);
   if(h_ma_slow!=INVALID_HANDLE) IndicatorRelease(h_ma_slow);
   if(h_ma_trend!=INVALID_HANDLE)IndicatorRelease(h_ma_trend);
   if(h_adx!=INVALID_HANDLE)     IndicatorRelease(h_adx);
   if(h_rsi!=INVALID_HANDLE)     IndicatorRelease(h_rsi);
   if(h_bb!=INVALID_HANDLE)      IndicatorRelease(h_bb);
   if(h_atr!=INVALID_HANDLE)     IndicatorRelease(h_atr);
   Print("🤖 Lion's Fury AI Elite Deinitialized - Reason: ",reason);
}

//------------------------------------------------------------------
//  MAIN TICK FUNCTION                                               |
//------------------------------------------------------------------
void OnTick()
{
   market_regime=CalculateMarketRegime();
   CalculateMultiTimeframeSignals();

   if(InpUseOrderBlocks)     DetectOrderBlocks();
   if(InpUseLiquidityLevels) DetectLiquidityLevels();

   liquidity_score=(double)liq_count/20.0;
   momentum_score =MathAbs(market_regime-1.0);
   volatility_score=CalculateVolatilityRegime()/2.0;
   trend_strength=MathAbs(market_regime-1.0);

   int signal=GetAISignal();
   if(!ValidateSignal(signal)) signal=0;
   if(!IsMarketStructureValid(signal)) signal=0;

   ManageAIPositions();
   ApplyBreakevenStop();

   if(PositionsTotal()==0) ExecuteAITrade(signal);
   if(InpUseGridScalping && signal!=0) ExecuteGridTrade(signal);

   static datetime last_update=0;
   if(TimeCurrent()-last_update>3600)
   { UpdateNeuralNetwork(ai_confidence); last_update=TimeCurrent(); }

   static int tick_cnt=0; tick_cnt++;
   if(tick_cnt%100==0)
      Print("🤖 Status - Confidence:",DoubleToString(ai_confidence,2),
            " | Regime:",market_regime,
            " | Positions:",PositionsTotal());
}

//------------------------------------------------------------------
//  TRADE TRANSACTION HANDLER                                        |
//------------------------------------------------------------------
void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
{
   if(trans.symbol==_Symbol && trans.type==TRADE_TRANSACTION_DEAL_ADD)
      Print("💰 Trade Executed: ",trans.deal," | Type: ",trans.order_type);
}

//------------------------------------------------------------------
//  EXTERNAL ACCESSOR FUNCTIONS                                      |
//------------------------------------------------------------------
double GetAIConfidence(){ return ai_confidence; }
double GetMarketRegime(){ return market_regime; }
int    GetActivePositions(){ return PositionsTotal(); }

double GetTotalProfit()
{
   double total=0.0;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL)==_Symbol)
         total+=PositionGetDouble(POSITION_PROFIT);
   }
   return total;
}