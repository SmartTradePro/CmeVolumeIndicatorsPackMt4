//+------------------------------------------------------------------+
//|                                            CME Market Profil.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrNONE


#include <Arrays\List.mqh>
#include <Arrays\ArrayString.mqh>
#include <Arrays\ArrayObj.mqh>
#include "ICmeProvider.mqh"
#ifdef __MQL4__
   #include "CmeProviderMT4.mqh"
#else 
   #include "CmeProviderMT5.mqh"
#endif
#include "Dictionary.mqh"
#include "MarketProfileCluster.mqh"

input ENUM_CME_VOL_TYPE VolType = CME_GLOBEX_VOLUME;           // Volume Type
input ENUM_PROFILE_TYPE Display = PROFILE_SINGLE;              // Display Type
input ENUM_CALC_TYPE CalculationType = CALC_WEIGHTED;
input ENUM_CLUSTER_PERIOD  ClusterPeriod = CLUSTER_MONTH;      // Cluster Period
input int            SinglePeriod = 24;                        // Single Period
input int            StepSize = 100;
input bool           AutoDetect = true;                        // Auto Detect Report Name 
input string         ReportName = "EURODOLLAR FUTURE (ED)";    // Report Name

CDictionary          Volumes;
CList                RangesFifo;
CArrayString         ObjectsList;
ICmeProvider*        CmeProvider = new CCmeProvider();   // CME Data Provider
double               buffer[];
int                  numbers = 0;
CMarketProfile*      MarketProfile;
CArrayObj            m_profiles;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   if(Display == PROFILE_SINGLE)
   {
      CMarketProfileSingle* single = new CMarketProfileSingle();
      single.SetStepSize(StepSize);
      single.SetPeriod(SinglePeriod);
      MarketProfile = single;
   }
   else
   {
      CMarketProfileCluster* cluster = new CMarketProfileCluster();
      cluster.SetStepSize(StepSize);
      cluster.SetPeriod(ClusterPeriod);
      MarketProfile = cluster;
   }
   if(!CmeProvider.InitProvider(Symbol(), Period(), VolType, AutoDetect, ReportName))
      return INIT_FAILED;
   string type_vol = CmeProvider.CmeVolumeToString(VolType);
   IndicatorSetString(INDICATOR_SHORTNAME, "CME Market Profile Delta" + type_vol);
   SetIndexBuffer(0, buffer, INDICATOR_DATA);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Deinit and free CmeProvider                                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(CheckPointer(CmeProvider) == POINTER_DYNAMIC)
   {
      CmeProvider.IndicatorRelease();
      delete CmeProvider;
   }
   if(CheckPointer(MarketProfile) == POINTER_DYNAMIC)
      delete MarketProfile;
}
//+------------------------------------------------------------------+
//| Redraw histogram                                                 |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long& lparam,
                  const double& dparam,
                  const string& sparam
                 )
{ 
   if(id == CHARTEVENT_CHART_CHANGE)
      MarketProfile.RefreshLines();
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
//---
   ArraySetAsSeries(buffer, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(tick_volume, true);
   
   for(int i = prev_calculated; i < rates_total-1; i++)
   {
      int bar = rates_total-i-1;
      buffer[bar] = close[bar];
      //-- get cme daily volume or stundart tick volume
      double cme_volume = CmeProvider.GetValue(bar);
      //-- calculate typing price
      if(cme_volume != EMPTY_VALUE)
         MarketProfile.RefreshLines(time[bar], high[bar], low[bar], cme_volume, false);
   }
   MarketProfile.RefreshLines();
   return(rates_total-1);
}

//+------------------------------------------------------------------+
//| Return true if new day detected, otherwise false                 |
//+------------------------------------------------------------------+
bool NewDay(datetime prev_time, datetime curr_time)
{
   MqlDateTime pt, ct;
   TimeToStruct(prev_time, pt);
   TimeToStruct(curr_time, ct);
   return pt.day != ct.day;
}

//+------------------------------------------------------------------+
