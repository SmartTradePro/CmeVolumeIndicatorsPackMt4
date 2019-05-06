//+------------------------------------------------------------------+
//|                                               Market Profile.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property strict
#include <Arrays\List.mqh>
#include <Arrays\ArrayString.mqh>
#include "Dictionary.mqh"
//+------------------------------------------------------------------+
//| Align of market profile gistogram distribution                   |
//+------------------------------------------------------------------+
enum ENUM_ALIGN_PROFILE
{
   ALIGN_PROFILE_RIGHT, // Right side
   ALIGN_PROFILE_LEFT   // Left side
};

enum ENUM_DRAW_TYPE
{
   DRAW_AS_TIME_TREND,
   DRAW_AS_RECTANGE_LABEL
};
//+------------------------------------------------------------------+
//| Type of market profile                                           |
//+------------------------------------------------------------------+
enum ENUM_PROFILE_TYPE
{
   PROFILE_SINGLE,   // Single
   PROFILE_CLUSTER   // Cluster
};
//+------------------------------------------------------------------+
//| Calculation type                                                 |
//+------------------------------------------------------------------+
enum ENUM_CALC_TYPE
{
   CALC_SIMPLE,      // Simple
   CALC_WEIGHTED     // Weighted
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMarketProfile : public CObject
{
public:
   //-- 
   virtual void        RefreshLines(datetime time, double high, double low, double volume, bool draw_hist){;}
   virtual void        RefreshLines(void){;}
};
//+------------------------------------------------------------------+
//| Distribution of price and volume on every day bar                |
//+------------------------------------------------------------------+
class CRange : public CObject
{
public:
   datetime    time;
   double      high;
   double      low;
   double      volume;
};
//+------------------------------------------------------------------+
//| Boxing for double                                                |
//+------------------------------------------------------------------+
class CDouble : public CObject
{
public:
   double value;
   CDouble():value(0.0){;}
   CDouble(double v):value(v){;}
};
//+------------------------------------------------------------------+
//| Market Profile                                                   |
//+------------------------------------------------------------------+
class CMarketProfileSingle : public CMarketProfile
{
private:
   int         m_period;            // Period of gistogram
   double      m_percent;           // Percent gistogram hight of screen
   CList       m_distr;             // Distributions of price and volumes as 
   int         m_step;
   CArrayString m_lines;
   ENUM_PROFILE_TYPE m_profile_type;
   ENUM_CALC_TYPE m_calc_type;
   CRange*     ToRange(datetime time, double high, double low, double volume);
   void        ShowHistogram(void);
   int         GetPriceStep(void);
   double      FindMaxVolume(CDictionary* volume);
   double      FindTimeLenghtMax(datetime time_begin);
   void        DrawLine(datetime time_begin, datetime time_end, double price, color clr);
   int         FindBeginPrice(double first_low_price, int step);
   double      LevelToPrice(int price_level);
   datetime    GetDrawBeginTime(void);
   datetime    FindTimeEndSingle(datetime time_begin, double max_volume, double curr_volume);
   datetime    FindTimeEndCluster(datetime time_begin, double max_volume, double curr_volume);
   CDictionary* BuildHistogram(void);
   int         PriceToLevel(double price);
   void        PlotRangeLine();
   void        HideHistogram(void);
public:
               CMarketProfileSingle(void);
               ~CMarketProfileSingle(void);
   //-- Set methods
   void        SetPeriod(int period);
   void        SetStepSize(int step_size);
   void        SetHistType(ENUM_PROFILE_TYPE profile_type);
   void        SetCalculationType(ENUM_CALC_TYPE calc_type);
   //-- Get methods
   int         GetPeriod(void);
   //-- 
   virtual void        RefreshLines(datetime time, double high, double low, double volume, bool draw_hist);
   virtual void        RefreshLines(void);
};
//+------------------------------------------------------------------+
//| Init parameters                                                  |
//+------------------------------------------------------------------+
CMarketProfileSingle::CMarketProfileSingle() : m_period(24),
                                   m_percent(0.25),
                                   m_profile_type(PROFILE_SINGLE),
                                   m_calc_type(CALC_WEIGHTED)
{
}
//+------------------------------------------------------------------+
//| Hide histogram                                                   |
//+------------------------------------------------------------------+
CMarketProfileSingle::~CMarketProfileSingle(void)
{
   HideHistogram();
}
//+------------------------------------------------------------------+
//| Set period of histogram build                                    |
//+------------------------------------------------------------------+
void CMarketProfileSingle::SetPeriod(int period)
{
   m_period = period;
}
//+------------------------------------------------------------------+
//| Set step size                                                    |
//+------------------------------------------------------------------+
void CMarketProfileSingle::SetStepSize(int step_size)
{
   m_step = step_size;
}
//+------------------------------------------------------------------+
//| Set history type                                                 |
//+------------------------------------------------------------------+
void CMarketProfileSingle::SetHistType(ENUM_PROFILE_TYPE profile_type)
{
   m_profile_type = profile_type;
}
//+------------------------------------------------------------------+
//| Set calculation type                                             |
//+------------------------------------------------------------------+
void CMarketProfileSingle::SetCalculationType(ENUM_CALC_TYPE calc_type)
{
   m_calc_type = calc_type;
}
//+------------------------------------------------------------------+
//| Get period of histogram build                                    |
//+------------------------------------------------------------------+
int CMarketProfileSingle::GetPeriod(void)
{
   return m_period;
}
//+------------------------------------------------------------------+
//| Create new CRange                                                |
//+------------------------------------------------------------------+
CRange* CMarketProfileSingle::ToRange(datetime time, double high, double low, double volume)
{
   CRange* range = new CRange();
   range.time = time;
   range.high = high;
   range.low = low;
   range.volume = volume;
   return range;
}
//+------------------------------------------------------------------+
//| Get width of one histogram line                                  |
//+------------------------------------------------------------------+
int CMarketProfileSingle::GetPriceStep(void)
{
   return m_step;
}
//+------------------------------------------------------------------+
//| Refresh market profile lines                                     |
//+------------------------------------------------------------------+
void CMarketProfileSingle::RefreshLines(void)
{
   HideHistogram();
   ShowHistogram();
}
//+------------------------------------------------------------------+
//| Refresh market profile lines                                     |
//+------------------------------------------------------------------+
void CMarketProfileSingle::RefreshLines(datetime time, double high, double low, double volume, bool draw_hist)
{
   if(draw_hist)
      HideHistogram();
   if(volume != EMPTY_VALUE)
   {
      CRange* range = ToRange(time, high, low, volume);
      m_distr.Add(range);
      if(m_distr.Total() > m_period)
      {
         m_distr.GetFirstNode();
         m_distr.DeleteCurrent();
      }
   }
   if(draw_hist && m_distr.Total() > 0)
      ShowHistogram();
}
//+------------------------------------------------------------------+
//| Show histogram                                                   |
//+------------------------------------------------------------------+
void CMarketProfileSingle::ShowHistogram(void)
{
   CDictionary* volumes = BuildHistogram();
   double max_volume = FindMaxVolume(volumes);
   datetime time_begin = GetDrawBeginTime();
   double prev_vol = 0.0;
   for(CDouble* cdouble = volumes.GetFirstNode(); cdouble != NULL; cdouble = volumes.GetNextNode())
   {
      double curr_volume = cdouble.value;
      color clr = clrRed;
      if(curr_volume >= prev_vol)
         clr = clrGreen;
      prev_vol = curr_volume;
      int price_level = 0.0;
      volumes.GetCurrentKey(price_level);
      double price = LevelToPrice(price_level);
      datetime time_end = 0;
      if(m_profile_type == PROFILE_SINGLE)
         time_end = FindTimeEndSingle(time_begin, max_volume, curr_volume);
      else
         time_end = FindTimeEndCluster(time_begin, max_volume, curr_volume);
      DrawLine(time_begin, time_end, price, clr);
      //if(time_end == 0)
      //   printf("Time end == 0, " + TimeToString(TimeCurrent()));
   }
   if(volumes.Total() > 0 && m_profile_type != PROFILE_CLUSTER)
      PlotRangeLine();
   delete volumes;
}
//+------------------------------------------------------------------+
//| Return time of begin line draw                                   |
//+------------------------------------------------------------------+
datetime CMarketProfileSingle::GetDrawBeginTime(void)
{
   if(m_profile_type == PROFILE_SINGLE)
      return iTime(Symbol(), Period(), WindowFirstVisibleBar());
   else if(m_profile_type == PROFILE_CLUSTER)
   {
      if(m_distr.Total() == 0)
         return 0;
      CRange* range = m_distr.GetFirstNode();
      return range.time;
   }
   return 0;
}
//+------------------------------------------------------------------+
//| Plot range line                                                  |
//+------------------------------------------------------------------+
void CMarketProfileSingle::PlotRangeLine(void)
{
   //-- draw scroll period
   CRange* first_range = m_distr.GetFirstNode();
   CRange* last_range = m_distr.GetLastNode();
   string name = "scroll_" + (string)m_lines.Total();
   datetime time;
   double price;
   long y = ChartGetInteger(ChartID(), CHART_HEIGHT_IN_PIXELS)-2;
   int sub = 0;
   ChartXYToTimePrice(ChartID(), 0, (int)y, sub, time, price);
   ObjectCreate(ChartID(), name, OBJ_TREND, 0, first_range.time, price , last_range.time, price);
   ObjectSetInteger(ChartID(), name, OBJPROP_RAY_RIGHT, false);
   m_lines.Add(name);
}
//+------------------------------------------------------------------+
//| Show histogram                                                   |
//+------------------------------------------------------------------+
CDictionary* CMarketProfileSingle::BuildHistogram(void)
{
   //-- find max and min
   CDictionary* volumes = new CDictionary();
   int step = GetPriceStep();
   for(CRange* range = m_distr.GetFirstNode(); range != NULL; range = m_distr.GetNextNode())
   {   
      int high_level = PriceToLevel(range.high);
      int begin_level = FindBeginPrice(range.low, step);
      double steps = m_calc_type == CALC_WEIGHTED ? (high_level-begin_level)/step : 1.0;
      if(steps == 0.0)
         steps = 1.0;
      for(int level = begin_level; level < high_level; level += step)
      {
         CDouble* cdouble = volumes.GetObjectByKey(level);
         if(cdouble == NULL)
            volumes.AddObject(level, new CDouble(range.volume/steps));   
         else
            cdouble.value += range.volume/steps;
      }
   }
   return volumes;
}
//+------------------------------------------------------------------+
//| Find trend line                                                  |
//+------------------------------------------------------------------+
datetime CMarketProfileSingle::FindTimeEndSingle(datetime time_begin, double max_volume, double curr_volume)
{
   double vol_ratio = curr_volume/max_volume;
   long screen_time = WindowBarsPerChart()*PeriodSeconds();
   long max_tiks = (long)MathRound(screen_time*m_percent);
   long curr_tiks = (long)MathRound(max_tiks*vol_ratio);
   int bars = (int)MathRound(curr_tiks/PeriodSeconds());
   int bar_first = iBarShift(Symbol(), Period(), time_begin);
   int bar_need = bar_first - bars;
   datetime time_end = iTime(Symbol(), Period(), bar_need);
   return time_end;
}
//+------------------------------------------------------------------+
//| Find trend line                                                  |
//+------------------------------------------------------------------+
datetime CMarketProfileSingle::FindTimeEndCluster(datetime time_begin, double max_volume, double curr_volume)
{
   int bars_min = MathMax(m_distr.Total(), 5);
   long max_tiks = bars_min*PeriodSeconds();
   double vol_ratio = curr_volume/max_volume;
   if(max_tiks == 0)
      printf("max_tiks == 0");
   long curr_tiks = (long)MathRound(max_tiks*vol_ratio);
   if(curr_tiks == 0)
      printf("curr_tiks == 0");
   int bars = (int)MathRound(curr_tiks/PeriodSeconds());
   int bar_first = iBarShift(Symbol(), Period(), time_begin);
   int bar_need = bar_first - bars;
   datetime time_end = time_begin + PeriodSeconds()*bars;
   return time_end;
}
//+------------------------------------------------------------------+
//| Draw line                                                        |
//+------------------------------------------------------------------+
void CMarketProfileSingle::DrawLine(datetime time_begin, datetime time_end, double price, color clr)
{
   string name = "mprof_" + (string)m_lines.Total() + "_" + (string)time_begin;
   if(ObjectCreate(ChartID(), name, OBJ_TREND, 0, time_begin, price , time_end, price))
   {
      m_lines.Add(name);
      ObjectSetInteger(ChartID(), name, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clr);
   }
}
//+------------------------------------------------------------------+
//| Find max cluster volume                                          |
//+------------------------------------------------------------------+
double CMarketProfileSingle::FindMaxVolume(CDictionary* volume)
{
   double max = 0.0;
   for(CDouble* cdouble = volume.GetFirstNode(); cdouble != NULL; cdouble = volume.GetNextNode())
   {
      if(cdouble.value > max)
         max = cdouble.value;
   }
   return max;
}
//+------------------------------------------------------------------+
//| Find time span lenght as double lenght                           |
//+------------------------------------------------------------------+
double CMarketProfileSingle::FindTimeLenghtMax(datetime time_begin)
{
   datetime time_max = time_begin + WindowBarsPerChart()*PeriodSeconds();
   double time_span = ((double)(time_max - time_begin)*m_percent);
   return time_span;
}
//+------------------------------------------------------------------+
//| Hide histogram                                                   |
//+------------------------------------------------------------------+
void CMarketProfileSingle::HideHistogram(void)
{
   for(int i = 0; i < m_lines.Total(); i++)
   {
      string name = m_lines.At(i);
      ObjectDelete(ChartID(), name);
   }
   m_lines.Clear();
}
//+------------------------------------------------------------------+
//| Find begin price                                                 |
//+------------------------------------------------------------------+
int CMarketProfileSingle::FindBeginPrice(double first_low_price, int step)
{
   int steps = (int)(first_low_price/Point());
   int step_count = steps/step;
   if(step_count*step < steps)
      step_count++;
   int begin_step = step_count * step;
   return begin_step;
}
int CMarketProfileSingle::PriceToLevel(double price)
{
   return int(price/Point());
}
double CMarketProfileSingle::LevelToPrice(int price_level)
{
   return price_level*Point();
}
