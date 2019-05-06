//+------------------------------------------------------------------+
//|                                             MarketProfilerSe.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property strict

#include <Arrays\ArrayObj.mqh>
#include "TimeChangeDetect.mqh"
#include "MarketProfileSingle.mqh"

#define SEC 1
#define MIN 2
#define HOR 4
#define DAY 8
#define WEK 16
#define MON 32
#define QUA 64
#define YER 128
//+------------------------------------------------------------------+
//| Hist delta period                                                |
//+------------------------------------------------------------------+
enum ENUM_CLUSTER_PERIOD
{
   CLUSTER_MONTH,    // Month
   CLUSTER_QUARTER   // Quarter
};
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
class CMarketProfileCluster : public CMarketProfile
{
private:
   ENUM_CLUSTER_PERIOD m_hist_period;
   int         m_step_size;
   datetime    m_prev_time;
   CArrayObj   m_profiles;
   CTimeChangeDetect m_detect;
   void        CreateNewHist(datetime time, double high, double low, double volume, bool draw_hist);
   void        AddInLastHist(datetime time, double high, double low, double volume, bool draw_hist);
   bool        NeedNewHist(datetime time_current);
public:
               CMarketProfileCluster(void);
   void        SetPeriod(ENUM_CLUSTER_PERIOD hist_period);
   void        SetStepSize(int step_size);
   //-- 
   virtual void        RefreshLines(datetime time, double high, double low, double volume, bool draw_hist);
   virtual void        RefreshLines(void);
};
//+------------------------------------------------------------------+
//| Init default                                                     |
//+------------------------------------------------------------------+
CMarketProfileCluster::CMarketProfileCluster(void) : m_prev_time(0)
{
}
//+------------------------------------------------------------------+
//| Set period                                                       |
//+------------------------------------------------------------------+
void CMarketProfileCluster::SetPeriod(ENUM_CLUSTER_PERIOD hist_period)
{
   m_hist_period = hist_period;
}
//+------------------------------------------------------------------+
//| Set step size                                                    |
//+------------------------------------------------------------------+
void CMarketProfileCluster::SetStepSize(int step_size)
{
   m_step_size = step_size;
}
//+------------------------------------------------------------------+
//| Refresh line                                                     |
//+------------------------------------------------------------------+
void CMarketProfileCluster::RefreshLines(datetime time,double high,double low, double volume, bool draw_hist)
{
   if(NeedNewHist(time))
   {
      int last = m_profiles.Total() - 1;
      if(last >= 0)
      {
         CMarketProfileSingle* prev_profile = m_profiles.At(last);
         prev_profile.RefreshLines();
      }
      CreateNewHist(time, high, low, volume, draw_hist);
      m_prev_time = time;
   }
   else
      AddInLastHist(time, high, low, volume, draw_hist);
}
//+------------------------------------------------------------------+
//| Refresh last frame                                               |
//+------------------------------------------------------------------+
void CMarketProfileCluster::RefreshLines(void)
{
   if(m_profiles.Total() == 0)
      return;
   int last = m_profiles.Total()-1;
   CMarketProfile* profiler = m_profiles.At(last);
   profiler.RefreshLines();
}
//+------------------------------------------------------------------+
//| Return true, if need create new histogram                        |
//+------------------------------------------------------------------+
bool CMarketProfileCluster::NeedNewHist(datetime time_current)
{
   if(m_profiles.Total() == 0)
      return true;
   uint flags = m_detect.ChangeTime(time_current);
   if(m_hist_period == CLUSTER_MONTH && (flags & CHANGE_MNT) == CHANGE_MNT)
      return true;
   if(m_hist_period == CLUSTER_QUARTER && (flags & CHANGE_QRT) == CHANGE_QRT)
      return true;
   return false;
}
//+------------------------------------------------------------------+
//| Create new histogram                                             |
//+------------------------------------------------------------------+
void CMarketProfileCluster::CreateNewHist(datetime time,double high,double low,double volume,bool draw_hist)
{
   CMarketProfileSingle* profile = new CMarketProfileSingle();
   profile.SetHistType(PROFILE_CLUSTER);
   profile.SetStepSize(m_step_size);
   profile.SetPeriod(10000);
   profile.RefreshLines(time, high, low, volume, draw_hist);
   m_profiles.Add(profile);
}
//+------------------------------------------------------------------+
//| Refresh last histogram                                           |
//+------------------------------------------------------------------+
void CMarketProfileCluster::AddInLastHist(datetime time,double high,double low,double volume,bool draw_hist)
{
   int last = m_profiles.Total()-1;
   CMarketProfileSingle* profiler = m_profiles.At(last);
   profiler.RefreshLines(time, high, low, volume, draw_hist);
   
}
//+------------------------------------------------------------------+
