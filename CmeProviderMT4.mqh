//+------------------------------------------------------------------+
//|                                                  CmeProvider.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "ICmeProvider.mqh"
//+------------------------------------------------------------------+
//| Cross-platform class for access indicators data                  |
//+------------------------------------------------------------------+
class CCmeProvider : public ICmeProvider
{
private:
   int             m_period;     // Period of indicator
   string          m_symbol;     // Symbol of indicator
   ENUM_CME_VOL_TYPE m_vol_type; // Volume type
   bool            m_auto_detect;
   string          m_report_name;
public:
                   CCmeProvider(void);
   //-- In MetaTrader 5 platform need initialize custom indicator in OnInit moment
   virtual bool    InitProvider(string symbol, int period, ENUM_CME_VOL_TYPE vol_type, bool auto_detect, string report_name);
   //-- override GetValue method
   virtual double  GetValue(int index);
};

//+------------------------------------------------------------------+
//| Init values by default                                           |
//+------------------------------------------------------------------+
CCmeProvider::CCmeProvider(void) : m_period(Period()),
                                   m_symbol(Symbol()),
                                   m_auto_detect(false),
                                   m_report_name("")
{
}
//+------------------------------------------------------------------+
//| Init handle of CME Data                                          |
//+------------------------------------------------------------------+
bool CCmeProvider::InitProvider(string symbol, int period, ENUM_CME_VOL_TYPE vol_type, bool auto_detect, string report_name)
{
   //-- 
   m_symbol = symbol;
   m_period = period;
   m_vol_type = vol_type;
   m_auto_detect = auto_detect;
   m_report_name = report_name;
   return true;
}
//+------------------------------------------------------------------+
//| Copy value by index                                              |
//+------------------------------------------------------------------+
double CCmeProvider::GetValue(int index)
{
   double value = EMPTY_VALUE;
   if(m_vol_type == CME_OPEN_INTEREST)
      value = iCustom(m_symbol, m_period, OiIndName(), m_auto_detect, m_report_name, false, 0, index);
   else if(m_vol_type == CME_CALL_PUT_RATIO)
      value = iCustom(m_symbol, m_period, CallPutIndName(), 2, CME_TOTAL_VOLUME, 1.0, 21, true, "call", "put", 0, 0, index);
   else
      value = iCustom(m_symbol, m_period, VolumeIndName(), CME_TOTAL_VOLUME, m_auto_detect, m_report_name, false, 0, index);
   
   return value;
}