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
   int             m_ind_handle;
   bool            m_was_init;
public:
                   CCmeProvider(void);
   //-- In MetaTrader 5 platform need initialize custom indicator in OnInit moment
   virtual bool    InitProvider(string symbol, int period, ENUM_CME_VOL_TYPE vol_type, bool auto_detect, string report_name);
   //-- override GetValue method
   virtual double  GetValue(int index);
   void            IndicatorRelease(void);
};

//+------------------------------------------------------------------+
//| Init values by default                                           |
//+------------------------------------------------------------------+
CCmeProvider::CCmeProvider(void) : m_ind_handle(INVALID_HANDLE),
                                   m_was_init(false)
{
}
//+------------------------------------------------------------------+
//| Init handle of CME Data                                          |
//+------------------------------------------------------------------+
bool CCmeProvider::InitProvider(string symbol, int period, ENUM_CME_VOL_TYPE vol_type, bool auto_detect, string report_name)
{
   if(m_ind_handle != INVALID_HANDLE)
      return true;
   if(m_was_init && m_ind_handle == INVALID_HANDLE)
      return false;
   ResetLastError();
   //-- 
   bool refresh_data_from_curr_ind = false;
   if(vol_type == CME_OPEN_INTEREST)
      m_ind_handle = iCustom(symbol, (ENUM_TIMEFRAMES)period, OiIndName(), auto_detect, report_name, refresh_data_from_curr_ind);
   else if(vol_type == TICK_VOLUME)
      m_ind_handle = iVolumes(symbol, (ENUM_TIMEFRAMES)period, VOLUME_TICK);
   else   
      m_ind_handle = iCustom(symbol, (ENUM_TIMEFRAMES)period, VolumeIndName(), vol_type, auto_detect, report_name, refresh_data_from_curr_ind);
   if(m_ind_handle == INVALID_HANDLE)
   {
      string ind_name = vol_type == CME_OPEN_INTEREST ? OiIndName() : VolumeIndName();
      printf("Failed create " + ind_name + " indicator handle. Error: " + (string)GetLastError());
   }
   m_was_init = m_ind_handle != INVALID_HANDLE;
   return m_was_init;
}
//+------------------------------------------------------------------+
//| Copy value by index                                              |
//+------------------------------------------------------------------+
double CCmeProvider::GetValue(int index)
{
   double array[1] = {EMPTY_VALUE};
   CopyBuffer(m_ind_handle, 0, index, 1, array);
   return array[0];
}
//+------------------------------------------------------------------+
//| Indicator Release                                                |
//+------------------------------------------------------------------+
void CCmeProvider::IndicatorRelease(void)
{
   if(m_ind_handle != INVALID_HANDLE)
      IndicatorRelease(m_ind_handle);
   m_ind_handle = INVALID_HANDLE;
   m_was_init = false;
}