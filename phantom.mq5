// +------------------------------------------------------------------+
// |                                                 Phantom MT5 .mq5 |
// |                        Copyright 2022, MetaQuotes Software Corp. |
// |                                             https://www.mql5.com |
// +------------------------------------------------------------------+

#property copyright "Copyright 2023 BlackswanFx.com"
#property link      "https:// blackswanfx.com/"
#property version   "1.00"

#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\HistoryOrderInfo.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\RadioButton.mqh>
#include <Controls\ListView.mqh>
#include <Controls\ComboBox.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\Label.mqh>
#include <Controls\Panel.mqh>
#include <Controls\BmpButton.mqh>
#include <Controls\Button.mqh>
#include <ChartObjects\ChartObjectsLines.mqh>
#include <ChartObjects\ChartObject.mqh>

#import "Wininet.dll"
int InternetOpenW(string, int, string, string, int);
int InternetConnectW(int, string, int, string, string, int, int, int);
int InternetOpenUrlW(int, string, string, int, int, int);
int InternetReadFile(int, uchar &arr[], int, int &arr[]);
int InternetCloseHandle(int);
#import

static int ErrorLevel = 3;
static int _OR_err = 0;

CSymbolInfo     o_symbol;
COrderInfo      o_order;
CPositionInfo   o_position;
COrderInfo      o_history;
CDealInfo       o_deal;
CTrade          o_trade;

string OrderReliable_Fname = "OrderReliable fname unset";
int retry_attempts = 10;
double sleep_time = 4.0;
double sleep_maximum = 25.0;  // in seconds
string symbol_;
string OrderReliableVersion = "v1_1_4";

string ErrorDescription(int error_code){
	return "Error " + IntegerToString(error_code);
}

enum ENUM_ADX_MAX_VALUE_ACTION
{
    PAUSE_START_TRADES, // Pause opening new trades
    CLOSE_ALL_TRADES    // Close all trades
};

enum trade_direction_type
{
	buy = 0,     // Long
	sell = 1,    // Short
	both = 2     // Both
};
enum phantom_trade_direction_type
{
	trend = 0,   // Trend
	counter = 1  // Counter
};
enum start_lots_type
{
	fixed = 0,   // Fixed Lots
	risk = 1     // Risk Level
};
enum pip_step_type
{
	psfixed = 0,     // Fixed
	psdynamic = 1,   // Dynamic
	pstime = 2,      // Time Based
	psstacked = 3    // Stacked
};
enum candle_filter_type
{
	candle_entry = 0,    // Start Trades
	candle_all = 1,      // All Trades
	candle_any = 2       // Candle Any
};
enum fb_profit_type
{
	pair = 0,            // Pair $
	account_dollar = 1,  // Account $
	account_perc = 2     // Account %
};
enum daily_goal_input
{
	acc_perc = 0,        // Account %
	acc_dollar = 1       // Account $
};
enum trail_stop_input
{
	start_trades = 0,    // Start Trades
	all_trades = 1       // All Trades
};
enum equity_protector_input
{
	ep_floating_loss = 0,        // Floating Loss
	ep_account_percent = 1,      // Account %
	ep_MDL_Balance = 2,          // MDL Balance
	ep_MDL_Equity = 3,           // MDL Equity
	ep_MDL_Highest_Value = 4     // MDL Highest Value
};
enum equity_protector_auto_resume_input
{
	ep_next_day = 0,     // Next Day
	ep_next_week = 1,    // Next Week
	ep_immediately = 2,  // Immediately
	ep_false = 3,        // False
};
enum slice_input
{
	slice_account_perc = 0,      // Account %
	slice_account_dollar = 1     // Account $
};
enum lot_multiplier_manager_input
{
	lmm_levels = 0,      // Levels
	lmm_perc_dd = 1      // % Drawdown
};
enum pip_step_manager_input
{
	psm_levels = 0,      // Levels
	psm_perc_dd = 1      // % Drawdown
};
enum news_action_input
{
	close_trades = 0,    // Close All Trades
	pause_trades = 1,    // Pause Trades
	none = 2             // None
};
enum TimeBaseEnum
{
    TIME_BASE_VPS,              // VPS Time
    TIME_BASE_MARKET_WATCH      // Market watch time
};

input int mn                        = 7776690;// Magic Number
input string SESSION_SETTINGS             = "----- SESSIONS ----- ";
input bool Sessions = true; // Sessions
input TimeBaseEnum TimeBase = TIME_BASE_VPS; // Base Time For Session
input int Broker_VPS_Time_Offset = 0; // Broker To VPS Offset Hours
input bool trade_Asia_Session   = true; // Trade Asia Session
input string Asia_Session_Start = "00:00"; // Asia Session Start
input string Asia_Session_End   = "08:00"; // Asia Session End
input bool trade_London_Session   = true; // Trade London Session
input string London_Session_Start = "08:00"; // London Session Start
input string London_Session_End   = "16:00"; // London Session End
input bool trade_NY_Session   = true; // Trade NY Session
input string NY_Session_Start = "13:00"; // NY Session Start
input string NY_Session_End   = "21:00"; // NY Session End
input string LOT_SETTINGS = "----- LOT SETTINGS -----";
input start_lots_type start_lots    = 0;// Starting Lot Type
input bool auto_scale               = false;// Compound Lots
input double per_cash_amount        = 1750;// Cash Amount
input double start_lots_val         = 0.01;// Starting Lot Size
input double lots_multiplier        = 2;// Lot Multiplier
input int lots_multiplier_interval  = 1;// Lot Multiplier Interval
input double max_lot_size           = 200;// Max Lot Size
input pip_step_type pip_step        = 0;// Pip Step Type
input int pip_step_amount           = 100;// Pip Step Amount
input double pip_step_multiplier    = 2;// Pip Step Multiplier
input int max_levels                = 20;// Max Trade Level
input string TRADE_SETTINGS         = "----- TRADE SETTINGS -----";
input trade_direction_type trade_direction = 2;// Trade Direction
input int seconds_entry_delay       = 0; // Entry delay Seconds (0 = disabled)
bool initialTradeDirection          = false;
input int time_between_trades_minutes = 3; // Time Between Trades (Mins)
input double threshold              = 0.1; // Define Your Threshold %
int current_level                   = 0; // A variable to keep track of current level, you need to update this accordingly
input string ADX_FILTER = "---------- ADX FILTER ----------";
input bool use_adx_filter = true;          // Use ADX filter
input ENUM_TIMEFRAMES ADX_Timeframe = PERIOD_H1;  // ADX Timeframe
input int ADX_Period = 14;                      // ADX Period
input double ADX_Max_Value = 25.0;              // ADX Max Value
input ENUM_ADX_MAX_VALUE_ACTION ADX_Max_Value_Action = PAUSE_START_TRADES; // ADX max Action
input string MOVING_AVERAGE_SETTINGS = "----- MOVING AVERAGE -----";
input bool USE_MA = false; // Use Moving Averages
input bool ma_entry_delay           = false;// MA Entry Delay
input bool use_ma1                  = false;// Use MA 1
input int MA_Entry_Direction        = -1; // MA Direction (1 Trend, -1 Counter)
input ENUM_TIMEFRAMES EMA_Timeframe_Filter = PERIOD_M1; // MA TimeFrame
input int ma1_period                = 10;// MA 1 Period
input ENUM_MA_METHOD ma1_method     = MODE_SMA;// MA 1 Method
input bool use_ma2                  = false;// Use MA 2
input int ma2_period                = 50;// MA 2 Period
input ENUM_MA_METHOD ma2_method     = MODE_SMA;// MA 2 Method
input bool use_ma3                  = false;// Use MA 3
input int ma3_period                = 100;// MA 3 Period
input ENUM_MA_METHOD ma3_method     = MODE_SMA;// MA 3 Method
input bool USE_PRICE_CROSSING_MA = true; // MA Close Confirmation
input string RSI_SETTINGS = "----- RSI -----";
input bool use_rsi_filter           = false;// Use RSI Filter
input int rsi_period                = 14;// RSI Period
input double rsi_upper              = 80;// RSI Upper Limit
input double rsi_lower              = 20;// RSI Lower Limit
input int RSI_Trend_Filter          = 1; // RSI Direction (1 Trend, -1 Counter)
input ENUM_TIMEFRAMES rsi_tf        = PERIOD_H1;// RSI Timeframe
input string OTHER_FILTER_SETTINGS = "----- OTHER FILTERS ------";
input bool use_spread_filter        = false;// Use Spread Filter
input int max_spread                = 5;// Max Allowed Spread
input bool use_candle_filter        = false;// Use Candlestick Filter
input candle_filter_type candle_filter = candle_entry;// Candle Filter Type
input ENUM_TIMEFRAMES candle_filter_tf = PERIOD_H1;// Candle Filter Timeframe
input int max_charts                = 0;// 
input string CSFM_SETTINGS = "----- CANDLESTICK FILTER MANAGER -----";
input bool use_candle_filter_manager = false;// Use CSFM
input int cfm_start                 = 5;// New CSF Timeframe Start
input ENUM_TIMEFRAMES cfm_timeframe = PERIOD_M5;// New CSF Timeframe
input string TAKE_PROFIT_SETTINGS           = "----- ACCOUNT TP -----";
input int tp_all_trades             = 50;// Take Profit (All Trades)
input bool use_acc_tp               = true;// Use Account Take Profit
input double acc_tp                 = 10000;// Account Take Profit
input string PA_SETTINGS = "----- PROFIT ACCUMULATION -----";
input bool use_profit_bucket        = false;// Use PA
input double profit_bucket_goal     = 100;// PA Goal
input bool profit_bucket_auto_reset = false;// PA Auto Reset
input string DPA_SETTINGS = "----- DYNAMIC PROFIT ACCUMULATION -----";
input bool use_floating_buckets     = false;// Use DPA
input fb_profit_type fb_type        = pair;// DPA Type
input double fb_goal                = 500;// DPA Goal
input double fb_start               = 250;// DPA Start
input double fb_stop                = 50;// DPA Stop
input bool fb_auto_reset            = false;// DPA Auto Reset
input string GOAL_SETTINGS = "----- DAILY/WEEKLY GOAL -----";
input bool use_daily_goal           = false;// Use Daily Goal
input daily_goal_input daily_goal_type = acc_dollar;// Daily Goal Type
input double daily_goal_amount      = 500;// Daily Goal Amount
input equity_protector_auto_resume_input resume_after_daily_goal = ep_next_day; // Resume After Daily Goal
input bool use_weekly_goal          = false;// Use Weekly Goal
input double weekly_goal_perc       = 1;// Weekly Goal (%)
input string STOP_LOSS_SETTINGS            = "----- ACCOUNT SL -----";
input int stop_loss_each_trade      = 0;// Stop Loss (Each Trade)
input bool use_acc_sl               = true;// Use Account Stop Loss
input double acc_sl                 = 9000;// Account Stop Loss
input string TRAILING_SL_SETTINGS = "----- TSL SETTINGS -----";
input bool use_trailing_stop_loss   = false;// Use Trailing Stop Loss
input trail_stop_input trail_stop_type = 0;// Trail Stop Type
input int trail_stop_start          = 50;// Trail Stop Start
input int trail_stop_stop           = 50;// Trail Stop Stop
input int trail_stop_interval       = 10;// Trail Stop Interval
input bool trail_stop_delete_tp     = false;// Delete TP When TSL Starts
input string EQUITY_PROTECTOR_SETTINGS = "---------- EP SETTINGS ----------";
input bool use_equity_protector     = false;// Use EP
input equity_protector_input equity_protector_type = 0;// EP Type
input equity_protector_auto_resume_input equity_protector_auto_resume_type = 0;// EP Auto Resume Type
input double equity_protector_value = 0;// Equity Protector Value
// Separate inputs for DD Management Settings
string dd_management_settings_separator = "---------- DD Management Settings ----------";
bool use_slice_mode = false;
slice_input slice_type = 0;
double slice_start = 0;
double slice_stop = 0;

// Separate inputs for Cut Mode Settings
string cut_mode_settings_separator = "---------- Cut Mode Settings ----------";
bool use_cut_mode = false;
int begin_cut_level = 10;

// Separate inputs for Chop Mode Settings
string chop_mode_settings_separator = "---------- Chop Mode Settings ----------";
bool use_chop_mode = false;
int chop_level = 15;
double chop_threshold_perc = 10;
int resume_chop = 1;

// Separate inputs for Lot Multiplier Manager Settings
string lot_multi_manager_settings_separator = "---------- Lot Multi Manager Settings ----------";
bool use_lot_multiplier_manager = false;
lot_multiplier_manager_input lmm_type = 0;
double lmm_multipler = 0.5;
double lmm_start = 4;
int lmm_interval = 1;

// Separate inputs for Pip Step Manager Settings
string pip_step_manager_settings_separator = "---------- Pip Step Manager Settings ----------";
bool use_pip_step_manager = false;
pip_step_manager_input psm_type = 0;
double psm_start = 4;
int psm_interval = 1;
double psm_multiplier = 2;

// Separate inputs for TP Manager Settings
string tp_manager_settings_separator = "---------- TP Manager Settings ----------";
bool use_tp_manager = false;
int tp_manager_start = 4;
int tp_manager_new_tp = 50;
int tp_manager_interval = 1;
int tp_manager_increment = 2;

// Separate inputs for Floating Bucket Manager Settings
string floating_bucket_manager_settings_separator = "---------- Floating Bucket Manager Settings ----------";
bool use_fb_manager = false;
double fbm_start = 100;
double fbm_new_goal = 20;
double fbm_interval = 20;
double fbm_increment = 5;
input string phantom_mode_settings_separator = "----- PHANTOM MODE (See Guide)----- ";
input bool use_phantom_trades       = false;// Use Phantom Trades
input int phantom_pip_step          = 100;// Phantom Pip Step
input int phantom_tp                = 50;// Phantom TP
input int phantom_levels            = 5;// Phantom Levels
input phantom_trade_direction_type phantom_direction = 0;// Phantom Entry Direction
input string SCHEDULE_SETTINGS = "----- DAILY SCHEDULE -----";
input bool Sunday                   = true;// Trade Sunday
input bool Monday                   = true;// Trade Monday
input bool Tuesday                  = true;// Trade Tuesday
input bool Wednesday                = true;// Trade Wednesday
input bool Thursday                 = true;// Trade Thursday
input bool Friday                   = true;// Trade Friday
input bool Saturday                 = true;// Trade Saturday
input bool use_close_all_trades     = false;// Use Close All Trades & Pause Start Trades at Day/Time
input int cat_day                   = 5;// Day of week (0 = Sunday, 1 = Monday etc.)
input string cat_time               = "23:00";// Time
input bool use_pause_trades         = false;// Use Pause Start Trades at Day/Time
input int pause_day                 = 3;// Pause Start Day
input string pause_time             = "12:00";// Pause Start Time
int opened_positions                = 0; // Variable to count the opened positions
input string start_trading          = "00:00";// Start Trading
input string stop_trading           = "23:59";// Stop Trading
input string NEWS_SETTINGS = "----- NEWS SETTINGS -----";

CAppDialog* m_panel;
CLabel m_pb_label, m_fb_label, m_weekly_label, m_ep_label, m_slice_label, m_cpip_label, m_phanlvls_label, m_maxcharts_label, m_basic_settings_label, m_tp_settings_label, m_account_tp_label, m_daily_goal_label, m_sl_settings_label, m_account_sl_label, m_daily_start_label, m_dd_settings_label, m_lot_mode_buy_label, m_lot_mode_sell_label, m_floating_bm_label, m_closeall_label;
CButton m_pb_reset_button, m_fb_reset_button, m_ep_reset_button, m_acc_tp_reset_button, m_acc_sl_reset_button, m_closeall_button;

bool phantom_buy, phantom_sell, pb_goal_reached;
string teststring = "tst";
int TimeDiff;

int phantom_buys, phantom_sells, charts_open;
double profit_bucket;

// #import "urlmon.dll"
// int URLDownloadToFileW(int pCaller, string szURL, string szFileName, int dwReserved, int Callback);
// #import

int URLDownloadToFileW(int pCaller, string szURL, string szFileName, int dwReserved, int Callback){
	return -1;
}

int DayCount            = 0;
datetime LastOrderTime  = 0;

// ---
#define INAME     "FFC"
#define TITLE     0
#define COUNTRY   1
#define DATE      2
#define TIME      3
#define IMPACT    4
#define FORECAST  5
#define PREVIOUS  6

// -------------------------------------------- inputAL VARIABLE ---------------------------------------------
// ------------------------------------------------------------------------------------------------------------
bool    ReportActive                = true;                 // Report for active chart only (override other inputs)
input bool enable_news              = true;// Enable News
input bool    IncludeHigh           = true;                 // Include high
input bool    IncludeMedium         = true;                 // Include medium
input bool    IncludeLow            = true;                // Include low
input int GMT_Offset                = 0;// GMT Offset
bool    IncludeSpeaks               = false;                 // Include speaks
bool    IncludeHolidays             = false;                 // Include holidays
int     FontSize                    = 10;                   // Display Font Size
string  FindKeyword                 = "";                   // Find keyword
string  IgnoreKeyword               = "";                   // Ignore keyword
bool    AllowUpdates                = true;                 // Allow updates
int     UpdateHour                  = 2;                    // Update every (in hours)
string   lb_0                       = "";                   // ------------------------------------------------------------
string   lb_1                       = "";                   // ------> PANEL SETTINGS
input bool    ShowPanel             = true;                 // Show News panel
bool    AllowSubwindow              = false;                // Show Panel in sub window
ENUM_BASE_CORNER Corner             = 2;                    // Panel side
string  PanelTitle = "Upcoming News Events"; // Panel title
color   TitleColor        = C'46,188,46';         // Title color
bool    ShowPanelBG       = true;                 // Show panel backgroud
color   Pbgc              = clrWhiteSmoke;          // Panel backgroud color
color   LowImpactColor    = C'91,192,222';        // Low impact color
color   MediumImpactColor = C'255,185,83';        // Medium impact color
color   HighImpactColor   = C'217,83,79';         // High impact color
color   HolidayColor      = clrOrchid;            // Holidays color
color   RemarksColor      = clrGray;              // Remarks color
color   PreviousColor     = C'170,170,170';       // Forecast color
color   PositiveColor     = C'46,188,46';         // Positive forecast color
color   NegativeColor     = clrTomato;            // Negative forecast color
input bool    ShowVerticalNews  = true;                 // Show news vertical lines
int     ChartTimeOffset   = 0;                    // Chart time offset (in hours)
int     EventDisplay      = 10;                   // Hide event after (in minutes)
string   lb_2              = "";                   // ------------------------------------------------------------
string   lb_3              = "";                   // ------> SYMBOL SETTINGS
bool    ReportForUSD      = true;                 // Report for USD
bool    ReportForEUR      = true;                 // Report for EUR
bool    ReportForGBP      = true;                 // Report for GBP
bool    ReportForNZD      = true;                 // Report for NZD
bool    ReportForJPY      = true;                 // Report for JPY
bool    ReportForAUD      = true;                 // Report for AUD
bool    ReportForCHF      = true;                 // Report for CHF
bool    ReportForCAD      = true;                 // Report for CAD
bool    ReportForCNY      = false;                // Report for CNY
string   lb_4              = "";                   // ------------------------------------------------------------
string   lb_5              = "";                   // ------> INFO SETTINGS
bool    ShowInfo          = true;                 // Show Symbol info ( Strength / Bar Time / Spread )
color   InfoColor         = C'255,185,83';        // Info color
int     InfoFontSize      = 8;                    // Info font size
string   lb_6              = "";                   // ------------------------------------------------------------
string   lb_7              = "";                   // ------> NOTIFICATION
string   lb_8              = "";                   // *Note: Set (-1) to disable the Alert
int     Alert1Minutes     = 30;                   // Minutes before first Alert
int     Alert2Minutes     = -1;                   // Minutes before second Alert
bool    PopupAlerts       = false;                // Popup Alerts
bool    SoundAlerts       = false;                 // Sound Alerts
string  AlertSoundFile    = "news.wav";           // Sound file name
bool    NotificationAlerts= false;                // Send push notification

input news_action_input high_action = pause_trades;// High News Action
input news_action_input med_action = pause_trades;// Med News Action
input news_action_input low_action = none;// Low News Action
input int news_action_minutes = 3;// News Action Minutes
// ------------------------------------------------------------------------------------------------------------
// --------------------------------------------- INTERNAL VARIABLE --------------------------------------------
// --- Vars and arrays
string xmlFileName;
string sData;
string Event[200][7];
string eTitle[10], eCountry[10], eImpact[10], eForecast[10], ePrevious[10];
int eMinutes[10];
datetime eTime[10];
int anchor_, x0, x1_, x2_, xf, xp;
int Factor;
// --- Alert
bool FirstAlert;
bool SecondAlert;
datetime AlertTime;
// --- Buffers
double MinuteBuffer[];
double ImpactBuffer[];
// --- time
datetime xmlModifed;
int TimeOfDay;
datetime Midnight;
bool IsEvent;

bool News_Close_Trades = false;
bool News_Pause_Trades = false;

datetime next_news_update;

int hRSI, hatrH1, hatrH4, hatrD1, hatrW1;

int hma1, hma2, hma3;

#define OP_BUY  0
#define OP_SELL  1
#define MODE_LOTSIZE 15

#define ERR_NO_CONNECTION 100
#define ERR_TRADE_CONTEXT_BUSY 101

#define ERR_NO_ERROR 102
#define ERR_NO_RESULT 103
#define ERR_SERVER_BUSY 104
#define ERR_INVALID_PRICE 106
#define ERR_OFF_QUOTES 107
#define ERR_BROKER_BUSY 108
#define ERR_TRADE_TIMEOUT 110
#define ERR_PRICE_CHANGED 111
#define ERR_REQUOTE 112

bool IsTesting() {
    return MQLInfoInteger(MQL_TESTER) == 1;
}

double AccountEquity() {
	return AccountInfoDouble(ACCOUNT_EQUITY);
}
double AccountBalance() {
	return AccountInfoDouble(ACCOUNT_BALANCE);
}
int AccountLeverage() {
	return (int)AccountInfoInteger(ACCOUNT_LEVERAGE);
}

bool IsFillingTypeAllowed(string symbol, int filll_type) {
	return !(filll_type != 0) || (int)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
}

double GetValue(int h, int shift = 0) {
	double res[1];
	if (CopyBuffer(h, 0, shift, 1, res)!=1) {
        return 0;
	}
	return res[0];
}

int GetLastTicket() {
	int ticket = 0;
    for (int i = PositionsTotal() - 1; i >= 0; --i)
    {
        if (!o_position.SelectByIndex(i)) {
            break;
        }
        if (o_position.Magic() == mn && o_position.Symbol() == Symbol()) {
            return (int)o_position.Ticket();
        }
    }
	return(ticket);
}

bool CheckEntryDelay() {
	return TimeCurrent() - LastOrderTime >= seconds_entry_delay || seconds_entry_delay == 0;
}

int OrderSend_(string symb, int type, double lots, double price, int dev, double sl, double tp) {
    if (!CheckEntryDelay()) {
        return GetLastTicket();
    }
	if (type == OP_BUY) {
        o_trade.Buy(lots, Symbol(), price, sl, tp, "");
	}
	if (type == OP_SELL) {
        o_trade.Sell(lots, Symbol(), price, sl, tp, "");
	}
    LastOrderTime = TimeCurrent();
	return GetLastTicket();
}

bool IsConnected(){
	return (bool)TerminalInfoInteger(TERMINAL_CONNECTED);
}

bool IsTradeAllowed(){
	return (bool)MQLInfoInteger(MQL_TRADE_ALLOWED);
}

bool IsOptimization(){
	return (bool)MQLInfoInteger(MQL_OPTIMIZATION);
}

int TimeDayOfWeek(datetime date)
{
	MqlDateTime tm;
	TimeToStruct(date, tm);
	return(tm.day_of_week);
}

void OrderPrint() {
    //  print fucking order
}

bool ObjectSet(string name, int index, double value)
{
	switch(index)
    {
    case OBJPROP_COLOR:
		ObjectSetInteger(0, name, OBJPROP_COLOR, (int)value);
	case OBJPROP_STYLE:
		ObjectSetInteger(0, name, OBJPROP_STYLE, (int)value);
	case OBJPROP_WIDTH:
		ObjectSetInteger(0, name, OBJPROP_WIDTH, (int)value);
	case OBJPROP_BACK:
		ObjectSetInteger(0, name, OBJPROP_BACK, (int)value);
	case OBJPROP_RAY:
		ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, (int)value);
	case OBJPROP_ELLIPSE:
		ObjectSetInteger(0, name, OBJPROP_ELLIPSE, (int)value);
	case OBJPROP_SCALE:
		ObjectSetDouble(0, name, OBJPROP_SCALE, value);
	case OBJPROP_ANGLE:
		ObjectSetDouble(0, name, OBJPROP_ANGLE, value);
	case OBJPROP_ARROWCODE:
		ObjectSetInteger(0, name, OBJPROP_ARROWCODE, (int)value);
	case OBJPROP_TIMEFRAMES:
		ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, (int)value);
	case OBJPROP_DEVIATION:
		ObjectSetDouble(0, name, OBJPROP_DEVIATION, value);
	case OBJPROP_FONTSIZE:
		ObjectSetInteger(0, name, OBJPROP_FONTSIZE, (int)value);
	case OBJPROP_CORNER:
		ObjectSetInteger(0, name, OBJPROP_CORNER, (int)value);
	case OBJPROP_XDISTANCE:
		ObjectSetInteger(0, name, OBJPROP_XDISTANCE, (int)value);
	case OBJPROP_YDISTANCE:
		ObjectSetInteger(0, name, OBJPROP_YDISTANCE, (int)value);
	case OBJPROP_LEVELCOLOR:
		ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR, (int)value);
	case OBJPROP_LEVELSTYLE:
		ObjectSetInteger(0, name, OBJPROP_LEVELSTYLE, (int)value);
	case OBJPROP_LEVELWIDTH:
		ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH, (int)value);
	default:
	    return false;
    }
	return true;
}

int TimeHour(datetime date)
{
	MqlDateTime tm;
	TimeToStruct(date, tm);
	return(tm.hour);
}

int TimeMinute(datetime date)
{
	MqlDateTime tm;
	TimeToStruct(date, tm);
	return(tm.min);
}

int Hour()
{
	MqlDateTime tm;
	TimeCurrent(tm);
	return(tm.hour);
}

int Minute()
{
	MqlDateTime tm;
	TimeCurrent(tm);
	return(tm.min);
}

int TimeDay(datetime date)
{
	MqlDateTime tm;
	TimeToStruct(date, tm);
	return(tm.day);
}

bool ObjectSetText(string name,
                       string text,
                       int font_size,
                       string font = "",
                       color text_color = CLR_NONE)
{
	int tmpObjType = (int)ObjectGetInteger(0, name, OBJPROP_TYPE);
	if (tmpObjType!=OBJ_LABEL && tmpObjType!=OBJ_TEXT) return(false);
	if (StringLen(text)>0 && font_size>0)
     {
      if (ObjectSetString(0, name, OBJPROP_TEXT, text)==true
         && ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size)==true)
        {
         if((StringLen(font)>0)
            && ObjectSetString(0, name, OBJPROP_FONT, font)==false)
            return(false);

         return(true);
        }
      return(false);
     }
	return(false);
}

// +------------------------------------------------------------------+
// | Expert initialization function                                   |
// +------------------------------------------------------------------+
int OnInit(void)
{
    // sets symbol name
	if (!o_symbol.Name(Symbol())) {
	    return INIT_FAILED;
	}
	o_trade.SetExpertMagicNumber(mn);
	if (IsFillingTypeAllowed(o_symbol.Name(), SYMBOL_FILLING_FOK))
	{
        o_trade.SetTypeFilling(ORDER_FILLING_FOK);
	} else if (IsFillingTypeAllowed(o_symbol.Name(), SYMBOL_FILLING_IOC)){
        o_trade.SetTypeFilling(SYMBOL_FILLING_IOC);
	} else {
      o_trade.SetTypeFilling(ORDER_FILLING_RETURN);
	}

	o_trade.SetDeviationInPoints(10);

	hRSI = iRSI(Symbol(), rsi_tf, rsi_period, PRICE_CLOSE);

	hatrH1 = iATR(Symbol(), PERIOD_H1, 3);
	hatrH4 = iATR(Symbol(), PERIOD_H4, 3);
	hatrD1 = iATR(Symbol(), PERIOD_D1, 3);
	hatrW1 = iATR(Symbol(), PERIOD_W1, 3);

	hma1 = iMA(Symbol(), EMA_Timeframe_Filter, ma1_period, 0, ma1_method, PRICE_CLOSE);
	hma2 = iMA(Symbol(), EMA_Timeframe_Filter, ma2_period, 0, ma2_method, PRICE_CLOSE);
	hma3 = iMA(Symbol(), EMA_Timeframe_Filter, ma3_period, 0, ma3_method, PRICE_CLOSE);

	ArrayResize(MinuteBuffer, Bars(Symbol(), PERIOD_CURRENT), 0);
	ArrayResize(ImpactBuffer, Bars(Symbol(), PERIOD_CURRENT), 0);
	
	TimeDiff = (int) (TimeLocal() - TimeCurrent());

	if (enable_news)
    {
        // --- get today time
        TimeOfDay = (int)TimeLocal()%86400;
        Midnight = TimeLocal()-TimeOfDay;
        // --- set xml file name ffcal_week_this (fixed name)
        xmlFileName = INAME+"-ffcal_week_this.xml";
        // --- checks the existence of the file.
        if (!FileIsExist(xmlFileName))
        {
            xmlDownload();
        }
        xmlRead();
        // --- get last modification time
        xmlModifed = (datetime)FileGetInteger(xmlFileName, FILE_MODIFY_DATE, false);
        // --- check for updates
        if (AllowUpdates)
        {
            if (xmlModifed < TimeLocal() - UpdateHour * 3600)
            {
                xmlUpdate();
            }
            // --- set timer to update old xml file every x hours
            // else
            //   EventSetTimer(UpdateHour*3600);
        }
        // --- set panel corner
        switch(Corner)
        {
            case CORNER_LEFT_UPPER:
                x0 = 5;
                x1_ = 165;
                x2_ = 15;
                xf = 340;
                xp = 390;
                anchor_ = 0;
                break;
            case CORNER_RIGHT_UPPER:
                x0 = 455;
                x1_ = 265;
                x2_ = 440;
                xf = 110;
                xp = 60;
                anchor_ = 0;
                break;
            case CORNER_RIGHT_LOWER:
                x0 = 455;
                x1_ = 265;
                x2_ = 440;
                xf = 110;
                xp = 60;
                anchor_ = 2;
                break;
            case CORNER_LEFT_LOWER:
                x0 = 5;
                x1_ = 165;
                x2_ = 15;
                xf = 340;
                xp = 390;
                anchor_ = 2;
            break;
        }
        UpdateNews();
    }
	m_panel = new CAppDialog();
	int panel_height = 360;
	if (use_acc_tp)
        panel_height += 20;
	if (use_profit_bucket)
        panel_height += 20;
	if (use_floating_buckets)
        panel_height += 20;
	if (use_weekly_goal)
		panel_height += 20;
	if (use_daily_goal)
		panel_height += 20;
	if (use_acc_sl)
		panel_height += 20;
	if (use_equity_protector)
		panel_height += 20;
	if (use_slice_mode)
		panel_height += 20;
	if (use_lot_multiplier_manager)
		panel_height += 20;
	if (use_lot_multiplier_manager)
		panel_height += 20;
	if (use_fb_manager)
		panel_height += 20;

	if (!(use_acc_tp || use_profit_bucket || use_floating_buckets || use_weekly_goal || use_daily_goal))
    {
        panel_height -= 40;
    }

	if (!(use_slice_mode || use_lot_multiplier_manager || use_fb_manager || use_equity_protector))
    {
		panel_height -= 40;
    }

	m_panel.Create(0,"Phantom MT5", 0, 100, 100, 420, panel_height);

	int x = 5;
	m_basic_settings_label.Create(0,"basic_settings_label", 0, 50, x, 5, 5);

	m_cpip_label.Create(0,"pipstep_label", 0,                       50, x += 20, 5, 5);
	m_phanlvls_label.Create(0,"phan_lvls_label", 0,                 50, x += 20, 85, 25);
	m_maxcharts_label.Create(0,"max_charts_label", 0,               50, x += 20, 85, 25);

	if (use_acc_tp || use_profit_bucket || use_floating_buckets || use_weekly_goal || use_daily_goal)
     {
      x += 20;
      m_tp_settings_label.Create(0,"tp_settings_label", 0,            50, x += 20, 85, 25);
     }

	if (use_acc_tp)
     {
      m_acc_tp_reset_button.Create(0,"acc_tp_reset_button", 0,        5, x += 20, 45, x+40);
      m_account_tp_label.Create(0,"account_tp_label", 0,              50, x, 85, 25);
     }

	if (use_profit_bucket)
     {
      m_pb_reset_button.Create(0,"pb_reset_button", 0,                5, x += 20, 45, x+40);
      m_pb_label.Create(0,"pb_label", 0,                              50, x, 85, 25);
     }

	if (use_floating_buckets)
     {
      m_fb_reset_button.Create(0,"FB_reset_button", 0,                5, x += 20, 45, x+40);
      m_fb_label.Create(0,"FB_label", 0,                              50, x, 85, 50);
     }
	if (use_weekly_goal)
      m_weekly_label.Create(0,"weekly_label", 0,                      50, x += 20, 85, 45);
	if (use_weekly_goal)
      m_daily_goal_label.Create(0,"daily_goal_label", 0,              50, x += 20, 85, 45);
	x += 20;
	m_sl_settings_label.Create(0,"sl_settings_label", 0,               50, x += 20, 85, 45);
	if (use_acc_sl)
     {
      m_acc_sl_reset_button.Create(0,"acc_sl_reset_button", 0,        5, x += 20, 45, x+40);
      m_account_sl_label.Create(0,"account_sl_label", 0,              50, x, 85, 45);
     }

	m_daily_start_label.Create(0,"daily_start_label", 0,               50, x += 20, 85, 45);

	if (use_equity_protector)
     {
      m_ep_reset_button.Create(0,"ep_reset_button", 0,                5, x += 20, 45, x+40);
      m_ep_label.Create(0,"ep_label", 0,                              50, x, 85, 45);
     }

	x += 20;
	if (use_slice_mode || use_lot_multiplier_manager || use_fb_manager)
     {
      m_dd_settings_label.Create(0,"dd_settings_label", 0,            50, x += 20, 85, 45);
      if (use_slice_mode)

         m_slice_label.Create(0,"slice_label", 0,                        50, x += 20, 85, 65);
      if (use_lot_multiplier_manager)
        {
         m_lot_mode_buy_label.Create(0,"lot_mode_buy_label", 0,          50, x += 20, 85, 65);
         m_lot_mode_sell_label.Create(0,"lot_mode_sell_label", 0,        50, x += 20, 85, 65);
        }
      if (use_fb_manager)
         m_floating_bm_label.Create(0,"floating_bm_label", 0,    50, x += 20, 85, 65);
     }

	m_closeall_button.Create(0,"closeall_button", 0,        240, x-20, 305, x);

	m_basic_settings_label.Text("Basic Settings");
	m_basic_settings_label.Font("Arial Bold");

	m_cpip_label.Text("Current Pip Step: 0");

	m_phanlvls_label.Text("Phantom Levels: 0");

	m_maxcharts_label.Text("Max Charts: 0/0");

	m_tp_settings_label.Text("TP Settings");
	m_tp_settings_label.Font("Arial Bold");

	m_account_tp_label.Text("Account TP: $0 / $0");

	m_acc_tp_reset_button.Text("Reset");
	m_acc_tp_reset_button.Color(clrGray);

	m_pb_label.Text("Profit Bucket: $0/$"+DoubleToString(profit_bucket_goal));

	m_pb_reset_button.Text("Reset");
	m_pb_reset_button.Color(clrGray);

	m_fb_label.Text("Floating Bucket: 0 / 0");

	m_fb_reset_button.Text("Reset");
	m_fb_reset_button.Color(clrGray);

	m_weekly_label.Text("Weekly Goal: 0% / "+DoubleToString(weekly_goal_perc)+"%");

	m_daily_goal_label.Text("Daily Goal: $0 / $0");


	m_sl_settings_label.Text("SL Settings");
	m_sl_settings_label.Font("Arial Bold");

	m_account_sl_label.Text("Account SL: $0 / $0");
	m_acc_sl_reset_button.Text("Reset");
	m_acc_sl_reset_button.Color(clrGray);

	m_daily_start_label.Text("Daily Start Balance: $0");

	m_ep_label.Text("Equity Protector: ");

	m_ep_reset_button.Text("Reset");
	m_ep_reset_button.Color(clrGray);

	m_dd_settings_label.Text("DD Settings");
	m_dd_settings_label.Font("Arial Bold");

	m_slice_label.Text("Slice Mode: OFF");

	m_lot_mode_buy_label.Text("Lot Mode Manager (Buy): OFF");

	m_lot_mode_sell_label.Text("Lot Mode Manager (Sell): OFF");

	m_floating_bm_label.Text("Floating Bucket Manager: OFF");

	m_closeall_button.Text("Close All");

	m_panel.Add(m_basic_settings_label);
	m_panel.Add(m_cpip_label);
	m_panel.Add(m_phanlvls_label);
	m_panel.Add(m_maxcharts_label);
	m_panel.Add(m_tp_settings_label);
	m_panel.Add(m_account_tp_label);
	m_panel.Add(m_pb_label);
	m_panel.Add(m_fb_label);
	m_panel.Add(m_weekly_label);
	m_panel.Add(m_daily_goal_label);
	m_panel.Add(m_sl_settings_label);
	m_panel.Add(m_account_sl_label);
	m_panel.Add(m_daily_start_label);
	m_panel.Add(m_dd_settings_label);
	m_panel.Add(m_slice_label);
	m_panel.Add(m_lot_mode_buy_label);
	m_panel.Add(m_lot_mode_sell_label);
	m_panel.Add(m_floating_bm_label);
	m_panel.Add(m_ep_label);

	m_panel.Add(m_pb_reset_button);
	m_panel.Add(m_fb_reset_button);
	m_panel.Add(m_ep_reset_button);
	m_panel.Add(m_acc_tp_reset_button);
	m_panel.Add(m_acc_sl_reset_button);
	m_panel.Add(m_closeall_button);

	m_panel.Run();

	UpdatePanelLabels();

	return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
	for(int i = ObjectsTotal(0); i>=0; i--)
     {
      string name = ObjectName(0, i);
      if (StringFind(name, INAME)==0)
         ObjectDelete(0, name);
     }
// --- Kill update timer only if removed
	if (reason==1)
      EventKillTimer();
	m_panel.Destroy(1);
	if (CheckPointer(m_panel)==POINTER_DYNAMIC)
      delete m_panel;
	ObjectsDeleteAll(0,"Phantom");
	if (IsTesting())
     {
      GlobalVariableDel(Symbol()+teststring+"-Phantom Buy");
      GlobalVariableDel(Symbol()+teststring+"-Phantom Sell");
      GlobalVariableDel(Symbol()+teststring+"-First Buy");
      GlobalVariableDel(Symbol()+teststring+"-First Sell");
      GlobalVariableDel(Symbol()+teststring+"-Trail Active Buy");
      GlobalVariableDel(Symbol()+teststring+"-Trail Active Sell");
      GlobalVariableDel(Symbol()+teststring+"-EP Hit");
      GlobalVariableDel(Symbol()+teststring+"-FB Hit");
      GlobalVariableDel("GEN"+teststring+"-FB Hit");
      GlobalVariableDel(teststring+"-Slice ON");
      GlobalVariableDel(Symbol()+teststring+"-Chop BUY reset");
      GlobalVariableDel(Symbol()+teststring+"-Chop BUY");
      GlobalVariableDel(Symbol()+teststring+"-Chop SELL reset");
      GlobalVariableDel(Symbol()+teststring+"-Chop SELL");
      GlobalVariableDel(Symbol()+teststring+"-LMM-BUY");
      GlobalVariableDel(Symbol()+teststring+"-LMM-SELL");
      GlobalVariableDel(Symbol()+teststring+"-PSM-BUY");
      GlobalVariableDel(Symbol()+teststring+"-PSM-SELL");
      GlobalVariableDel(Symbol()+teststring+"-TPM-BUY");
      GlobalVariableDel(Symbol()+teststring+"-TPM-SELL");
      GlobalVariableDel(Symbol()+teststring+"-FBM");
      GlobalVariableDel(Symbol()+teststring+"-FBM-Goal");
      GlobalVariableDel(Symbol()+teststring+"MR-Trail-HWM");
      GlobalVariableDel(Symbol()+teststring+"-CFM-BUY");
      GlobalVariableDel(Symbol()+teststring+"-CFM-SELL");
      GlobalVariableDel("GEN"+teststring+"-CloseForWeek");
      GlobalVariableDel(Symbol()+teststring+"-PAUSE-BUY");
      GlobalVariableDel(Symbol()+teststring+"-PAUSE-SELL");
      GlobalVariableDel(Symbol()+teststring+"-PAUSE-ACTIVE");
      GlobalVariableDel("GEN"+teststring+"-ACC_SL_HIT");
      GlobalVariableDel("DailyCheck"+teststring);
      GlobalVariableDel("DailyStartBalance"+teststring);
      GlobalVariableDel("DailyStartEquity"+teststring);
      GlobalVariableDel(Symbol()+teststring+"PB_Goal_Reached");
      GlobalVariableDel("GEN"+teststring+"-ACC_TP_HIT");
     }
}

//  Function to check if the ADX value is below the maximum threshold
bool IsADXBelowThreshold()
{
    return iADX(Symbol(), ADX_Timeframe, ADX_Period) < ADX_Max_Value;
}

bool TradingSession()
{
    // If sessions are not enabled, return false immediately
    if (!Sessions)
    {
        return false;
    }

    int offsetInSeconds = Broker_VPS_Time_Offset * 60 * 60;

    MqlDateTime struct_time;
    datetime current_time = TimeCurrent();
    TimeToStruct(current_time, struct_time);

    datetime Asia_start_time = StringToTime(Asia_Session_Start) + offsetInSeconds;
    datetime Asia_end_time = StringToTime(Asia_Session_End) + offsetInSeconds;

    datetime London_start_time = StringToTime(London_Session_Start) + offsetInSeconds;
    datetime London_end_time = StringToTime(London_Session_End) + offsetInSeconds;

    datetime NY_start_time = StringToTime(NY_Session_Start) + offsetInSeconds;
    datetime NY_end_time = StringToTime(NY_Session_End) + offsetInSeconds;

    return (trade_Asia_Session && current_time >= Asia_start_time && current_time <= Asia_end_time)
        || (trade_London_Session && current_time >= London_start_time && current_time <= London_end_time)
        || (trade_NY_Session && current_time >= NY_start_time && current_time <= NY_end_time);
}

datetime GetVPSTime()
{
    return TimeCurrent() + Broker_VPS_Time_Offset * 60 * 60;
}

void OnTick()
{
    datetime currentTime = 0;               // Initialize with a default value

    if (TimeBase == TIME_BASE_MARKET_WATCH) {
        currentTime = TimeCurrent();        // Market watch time
    } else if (TimeBase == TIME_BASE_VPS) {
        currentTime = GetVPSTime();         // VPS Time
    }

    CheckUpdateNews();

    News_Close_Trades = false;
    News_Pause_Trades = false;

    if (enable_news && !IsTesting()) {
        UpdateNews();
    }

    if (News_Close_Trades) {
        NewsCloseTrades();
    }

    CheckDailyValues();
    UpdatePanelLabels();
    ResetEquityProtector();
    if (use_slice_mode) {
        CheckSliceON();
    }
    ResetChop();

    if (use_close_all_trades) {
        CloseAllTradesOnTime(cat_day, cat_time);
    }
    if (use_pause_trades)
        PauseAllTradesOnTime(pause_day, pause_time);

    if (GlobalVariableGet(Symbol() + teststring + "-PAUSE-ACTIVE") <= 0)
    {
        GlobalVariableDel(Symbol() + teststring + "-PAUSE-BUY");
        GlobalVariableDel(Symbol() + teststring + "-PAUSE-SELL");
    }

    // Add the resume logic here
    datetime start_of_day = iTime(Symbol(), PERIOD_D1, 0);
    datetime start_of_week = iTime(Symbol(), PERIOD_W1, 0);

    if((GlobalVariableGet(Symbol()+teststring+"-PAUSE-BUY")==1 || GlobalVariableGet(Symbol()+teststring+"-PAUSE-SELL")==1)
        && ((resume_after_daily_goal == ep_next_day && currentTime >= start_of_day)
        || (resume_after_daily_goal == ep_next_week && TimeDayOfWeek(currentTime) == 1 && currentTime >= start_of_week)))
    {
        GlobalVariableSet(Symbol()+teststring+"-PAUSE-BUY", 0);
        GlobalVariableSet(Symbol()+teststring+"-PAUSE-SELL", 0);
    }

    double Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

    int buys = 0, sells = 0;
    double profit = 0;

    if (PositionsTotal() > 0)
    {
        for(int i = PositionsTotal() - 1 ; i >= 0 ; i--)
        {
            if (!o_position.SelectByIndex(i)){break;}

            if (o_position.Magic() == mn && o_position.Symbol() == Symbol())
            {
                if (o_position.PositionType() == POSITION_TYPE_BUY){buys++;}
                if (o_position.PositionType() == POSITION_TYPE_SELL){sells++;}

                profit += o_position.Profit() + o_position.Commission() + o_position.Swap();
            }
        }
    }



    // Check ADX Filter
    if (use_adx_filter && !IsADXBelowThreshold())
    {
        if (ADX_Max_Value_Action == PAUSE_START_TRADES)
        {
            // Logic for pausing trades
            GlobalVariableSet(Symbol() + teststring + "-PAUSE-ACTIVE", 1);
        }
        else if (ADX_Max_Value_Action == CLOSE_ALL_TRADES)
        {
            // Logic for closing all trades
            for (int i = PositionsTotal() - 1; i >= 0; i--)
            {
                if (!o_position.SelectByIndex(i)){break;}
                if (o_position.Magic() == mn && o_position.Symbol() == Symbol())
                {
                    // Add logic here to close the selected position
                }
            }
        }
    }




    if (use_cut_mode)
        UpdateCut(buys, sells);

    // Enable Candle Filter Manager
    if (buys >= cfm_start && use_candle_filter_manager)
        GlobalVariableSet(Symbol() + teststring + "-CFM-BUY", 1);
    if (sells >= cfm_start && use_candle_filter_manager)
        GlobalVariableSet(Symbol() + teststring + "-CFM-SELL", 1);

    if (buys < cfm_start)
        GlobalVariableDel(Symbol() + teststring + "-CFM-BUY");
    if (sells < cfm_start)
        GlobalVariableDel(Symbol() + teststring + "-CFM-SELL");

    // Enable Floating Bucket Manager
    if (use_fb_manager)
    {
        if (profit <= (fbm_start * -1))
        {
            GlobalVariableSet(Symbol() + teststring + "-FBM", 1);
        }
    }

    // Enable Lot Manager
    if (buys >= lmm_start && lmm_type == 0 && use_lot_multiplier_manager)
        GlobalVariableSet(Symbol() + teststring + "-LMM-BUY", 1);
    if (sells >= lmm_start && lmm_type == 0 && use_lot_multiplier_manager)
        GlobalVariableSet(Symbol() + teststring + "-LMM-SELL", 1);

    if (lmm_type == 0 && buys < lmm_start)
        GlobalVariableDel(Symbol() + teststring + "-LMM-BUY");
    if (lmm_type == 0 && sells < lmm_start)
        GlobalVariableDel(Symbol() + teststring + "-LMM-SELL");

    // Enable Pip Step Manager
    if (buys >= psm_start && psm_type == 0 && use_pip_step_manager && GlobalVariableGet(Symbol() + teststring + "-PSM-BUY") <= 0)
        GlobalVariableSet(Symbol() + teststring + "-PSM-BUY", buys);
    if (sells >= psm_start && psm_type == 0 && use_pip_step_manager && GlobalVariableGet(Symbol() + teststring + "-PSM-SELL") <= 0)
        GlobalVariableSet(Symbol() + teststring + "-PSM-SELL", sells);

    if (psm_type == 0 && buys < psm_start)
        GlobalVariableDel(Symbol() + teststring + "-PSM-BUY");
    if (psm_type == 0 && sells < psm_start)
        GlobalVariableDel(Symbol() + teststring + "-PSM-SELL");

    if ((((AccountEquity() - AccountBalance()) / AccountBalance()) * 100) <= lmm_start * -1 && lmm_type == 1 && use_lot_multiplier_manager)
    {
        GlobalVariableSet(Symbol() + teststring + "-LMM-SELL", 1);
        GlobalVariableSet(Symbol() + teststring + "-LMM-BUY", 1);
    }
    else
    {
        if (lmm_type == 1)
        {
            GlobalVariableDel(Symbol() + teststring + "-LMM-BUY");
            GlobalVariableDel(Symbol() + teststring + "-LMM-SELL");
        }
    }

    if ((((AccountEquity() - AccountBalance()) / AccountBalance()) * 100) <= psm_start * -1 && psm_type == 1 && use_pip_step_manager)
    {
        GlobalVariableSet(Symbol() + teststring + "-PSM-SELL", sells);
        GlobalVariableSet(Symbol() + teststring + "-PSM-BUY", buys);
    }
    else
    {
        if (lmm_type == 1)
        {
            GlobalVariableDel(Symbol() + teststring + "-PSM-BUY");
            GlobalVariableDel(Symbol() + teststring + "-PSM-SELL");
        }
    }

    // Enable TP manager
    if (use_tp_manager && buys >= tp_manager_start)
        GlobalVariableSet(Symbol() + teststring + "-TPM-BUY", 1);
    if (use_tp_manager && sells >= tp_manager_start)
        GlobalVariableSet(Symbol() + teststring + "-TPM-SELL", 1);
    if (use_tp_manager && buys < tp_manager_start)
        GlobalVariableDel(Symbol() + teststring + "-TPM-BUY");
    if (use_tp_manager && sells < tp_manager_start)
        GlobalVariableDel(Symbol() + teststring + "-TPM-SELL");

    phantom_buy            = GlobalVariableGet(Symbol() + teststring + "-Phantom Buy");
    phantom_sell           = GlobalVariableGet(Symbol() + teststring + "-Phantom Sell");
    pb_goal_reached        = GlobalVariableGet(Symbol() + teststring + "PB_Goal_Reached");
    bool fb_hit            = (GlobalVariableGet("GEN" + teststring + "-FB Hit") >= 1 || GlobalVariableGet(Symbol() + teststring + "-FB Hit") >= 1);
    bool weekly_goal_hit   = WeekProfitPerc() >= weekly_goal_perc;
    bool equity_protector_hit = GlobalVariableGet(Symbol() + teststring + "-EP Hit") > 0;
    bool slice_on          = GlobalVariableGet(teststring + "-Slice ON") > 0;
    bool chop_buy_active   = GlobalVariableGet(Symbol() + teststring + "-Chop BUY reset") > 0;
    bool chop_sell_active  = GlobalVariableGet(Symbol() + teststring + "-Chop SELL reset") > 0;
    bool close_for_week    = GlobalVariableGet("GEN" + teststring + "-CloseForWeek") > 0;
    bool pause_buy         = GlobalVariableGet(Symbol() + teststring + "-PAUSE-BUY") > 0;
    bool pause_sell        = GlobalVariableGet(Symbol() + teststring + "-PAUSE-SELL") > 0;
    bool acc_sl_hit        = GlobalVariableGet("GEN" + teststring + "-ACC_SL_HIT") > 0;
    bool acc_tp_hit        = GlobalVariableGet("GEN" + teststring + "-ACC_TP_HIT") > 0;


    if (TradingSession() &&
        ((SPREAD_GO() && use_spread_filter) || !use_spread_filter) &&
        ((!equity_protector_hit && use_equity_protector) || !use_equity_protector) &&
        ((!slice_on && use_slice_mode) || !use_slice_mode))
    {
      Print("isTradingEnabled = ", isTradingEnabled);
        double lots = GetStartLots();
    if (isTradingEnabled &&
        (!GlobalVariableGet(Symbol()+teststring+"-PAUSE-BUY")) && // Replace pause_buy
        buys <= 0 &&
        (trade_direction == 0 || trade_direction == 2) &&
            ((MA_BUY_ENTRY() && ma_entry_delay) || !ma_entry_delay) &&
        ((RSI_BUY() && use_rsi_filter) || !use_rsi_filter) &&
        ADX_BUY_ENTRY() &&
        CANDLE_BUY() &&
        MAX_CHARTS() &&
        (!use_profit_bucket || !pb_goal_reached) &&
        (!use_floating_buckets || !fb_hit) &&
        (!use_weekly_goal || !weekly_goal_hit) &&
        (!use_phantom_trades || phantom_buy) &&
        TradingDayOfWeek(Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday) &&
        (!chop_buy_active || !use_chop_mode) &&
        (!close_for_week) &&
        (!pause_buy) &&
        (!acc_sl_hit || !use_acc_sl) &&
        (!acc_tp_hit || !use_acc_tp) &&
        (!News_Close_Trades) &&
        (!News_Pause_Trades) &&
        ((MA_Entry_Direction == 1 && IsUptrend()) || (MA_Entry_Direction == -1 && !IsUptrend()))) // Add MA_Entry_Direction check
    {
       double sl = 0;
            if (stop_loss_each_trade > 0)
                sl = Ask - (stop_loss_each_trade * Point());
            int buy = OrderSend_(Symbol(), OP_BUY, lots, Ask, 10, sl, 0);// OrderSend(Symbol(), OP_BUY, lots, Ask, 10, sl, 0, "", mn, 0, clrNONE);
            if (buy <= 0)
            {
                Print("OrderSend Error: " + IntegerToString(GetLastError()));
            }
            else
            {
                GlobalVariableSet(Symbol() + teststring + "-First Buy", buy);
                GlobalVariableDel(Symbol() + teststring + "-Trail Active Buy");
            }
        }
    if (isTradingEnabled &&
        (!GlobalVariableGet(Symbol()+teststring+"-PAUSE-SELL")) && // Replace pause_sell
        sells <= 0 &&
        (trade_direction == 1 || trade_direction == 2) &&
        ((MA_SELL_ENTRY() && ma_entry_delay) || !ma_entry_delay) &&
        ((RSI_SELL() && use_rsi_filter)  || !use_rsi_filter) &&
         ADX_SELL_ENTRY() &&
        CANDLE_SELL() &&
        MAX_CHARTS() &&
        (!use_profit_bucket || !pb_goal_reached) &&
        (!use_floating_buckets || !fb_hit) &&
        (!use_weekly_goal || !weekly_goal_hit) &&
        (!use_phantom_trades || phantom_sell) &&
        TradingDayOfWeek(Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday) &&
        (!chop_sell_active || !use_chop_mode) &&
        (!close_for_week) &&
        (!pause_sell) &&
        (!acc_sl_hit || !use_acc_sl) &&
        (!acc_tp_hit || !use_acc_tp) &&
        (!News_Close_Trades) &&
        (!News_Pause_Trades) &&
        ((MA_Entry_Direction == 1 && !IsUptrend()) || (MA_Entry_Direction == -1 && IsUptrend()))) // Add MA_Entry_Direction check

            {
                double sl = 0;
                if (stop_loss_each_trade > 0)
                    sl = Bid + (stop_loss_each_trade * Point());
                int sell = OrderSend_(Symbol(), OP_SELL, lots, Bid, 10, sl, 0);// OrderSend(Symbol(), OP_SELL, lots, Bid, 10, sl, 0, "", mn, 0, clrNONE);
                if (sell <= 0)
                {
                    Print("OrderSend Error: " + IntegerToString(GetLastError()));
                }
                else
                {
                    GlobalVariableSet(Symbol() + teststring + "-First Sell", sell);
                    GlobalVariableDel(Symbol() + teststring + "-Trail Active Sell");
                }
            }
        }

    if (!use_phantom_trades || phantom_buy || phantom_sell)
        CheckNewLevels();
    if (use_phantom_trades)
    {
        CheckNewPhantomLevels();
        ManagePhantomTP();
    }
    if (tp_all_trades > 0)
    {
        ManageTP_BUYS();
        ManageTP_SELLS();
    }
    if (use_trailing_stop_loss)
        Manage_Trail();

    if (use_acc_tp && !use_floating_buckets)
        CheckAccountTP();
    if (use_floating_buckets)
        CheckFloatingBucket();
    if (use_daily_goal)
        CheckDailyGoal();
    if (use_acc_sl)
        CheckAccountSL();
    if (use_profit_bucket)
    {
        InitProfitBucket();
        CheckProfitBucket();
    }
    if (use_equity_protector)
    {
        CheckEquityProtector();
    }
    if (use_chop_mode)
    {
        Chop();
    }

    if (current_level >= 2)
    {
        // Here you can implement your logic for 'max_levels'
        // For example, you can control the trade volume or the number of trades based on max_levels
    }
}

// +------------------------------------------------------------------+
bool CANDLE_BUY()
{
	if (!use_candle_filter || candle_filter==candle_any)
      return true;

	ENUM_TIMEFRAMES new_tf = candle_filter_tf;
	if (GlobalVariableGet(Symbol()+teststring+"-CFM-BUY")>0)
      new_tf = cfm_timeframe;

	return (iClose(Symbol(), new_tf, 1)>iOpen(Symbol(), new_tf, 1));
}
// +------------------------------------------------------------------+
// |                                                                  |
// +------------------------------------------------------------------+
bool CANDLE_SELL()
{
	if (!use_candle_filter || candle_filter==candle_any)
      return true;

	ENUM_TIMEFRAMES new_tf = candle_filter_tf;
	if (GlobalVariableGet(Symbol()+teststring+"-CFM-SELL")>0)
      new_tf = cfm_timeframe;

	return (iClose(Symbol(), new_tf, 1)<iOpen(Symbol(), new_tf, 1));
}
// +------------------------------------------------------------------+
// |                                                                  |
// +------------------------------------------------------------------+
bool CANDLE_BUY_ACTIVE()
{
	if (!use_candle_filter || candle_filter==candle_entry)
      return true;

	ENUM_TIMEFRAMES new_tf = candle_filter_tf;
	if (GlobalVariableGet(Symbol()+teststring+"-CFM-BUY")>0)
      new_tf = cfm_timeframe;

	return (iClose(Symbol(), new_tf, 1)>iOpen(Symbol(), new_tf, 1));
}
// +------------------------------------------------------------------+
// |                                                                  |
// +------------------------------------------------------------------+
bool CANDLE_SELL_ACTIVE()
{
	if (!use_candle_filter || candle_filter==candle_entry)
      return true;

	ENUM_TIMEFRAMES new_tf = candle_filter_tf;
	if (GlobalVariableGet(Symbol()+teststring+"-CFM-SELL")>0)
      new_tf = cfm_timeframe;

	return (iClose(Symbol(), new_tf, 1)<iOpen(Symbol(), new_tf, 1));
}
// +------------------------------------------------------------------+
// |                                                                  |
// +------------------------------------------------------------------+
double GetStartLots()
{

	if (auto_scale)
     {
      return (AccountBalance()/per_cash_amount)*start_lots_val;
     }

	if (start_lots==0)
     {
      return start_lots_val;

     }
	if (start_lots==1)
     {
      return ((((AccountBalance() * AccountLeverage()/SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE)) * start_lots_val)/100))/10;
     }
	return start_lots_val;
}
// +------------------------------------------------------------------+
void CheckNewLevels()
{
	double Buys[];
	double Sells[];
	bool buy_cut = GlobalVariableGet(Symbol()+teststring+"-Buy CUT")>0;
	bool sell_cut = GlobalVariableGet(Symbol()+teststring+"-Sell CUT")>0;

	ArrayResize(Buys, 0, 0);
	ArrayResize(Sells, 0, 0);

	double Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
	double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

	datetime lastbuytime = 0, lastselltime = 0;
	int lastbuyticket = 0, lastsellticket = 0;
	double highestbuy = 0;
	double highestsell = 0;
	double lowestbuy = 10000000;
	double lowestsell = 10000000;
	int cut_sell = 0, cut_buy = 0;
	double cut_sell_price = 100000;
	double cut_buy_price = 0;
	for(int i = PositionsTotal() - 1; i>=0; i--)
     {
      if (!o_position.SelectByIndex(i)) {break;}

      if (o_position.Symbol()==Symbol() && o_position.Magic()==mn)
        {
         if (o_position.PositionType()==POSITION_TYPE_BUY)
           {
            if (o_position.PriceOpen()>cut_buy_price)
              {
               cut_buy_price  = o_position.PriceOpen();
               cut_buy        = (int)o_position.Ticket();
              }
            if (o_position.PriceOpen()>highestbuy)
               highestbuy = o_position.PriceOpen();
            if (o_position.PriceOpen()<lowestbuy)
               lowestbuy = o_position.PriceOpen();
            ArrayResize(Buys, ArraySize(Buys)+1, 0);
            Buys[ArraySize(Buys)-1]=o_position.Volume();
            if (o_position.Time()>lastbuytime)
              {
               lastbuytime    = o_position.Time();
               lastbuyticket  = (int)o_position.Ticket();
              }
           }
         if (o_position.PositionType()==POSITION_TYPE_SELL)
           {

            if (o_position.PriceOpen()<cut_sell_price)
              {
               cut_sell_price = o_position.PriceOpen();
               cut_sell       = (int)o_position.Ticket();
              }
            if (o_position.PriceOpen()>highestsell)
               highestsell    = o_position.PriceOpen();
            if (o_position.PriceOpen()<lowestsell)
               lowestsell     = o_position.PriceOpen();
            ArrayResize(Sells, ArraySize(Sells)+1, 0);
            Sells[ArraySize(Sells)-1] = o_position.Volume();
            if (o_position.Time()>lastselltime)
              {
               lastselltime   = o_position.Time();
               lastsellticket = (int)o_position.Ticket();
              }
           }
        }
     }

	if (ArraySize(Buys)>0)
      GlobalVariableDel(Symbol()+teststring+"-Phantom Buy");
	if (ArraySize(Sells)>0)
      GlobalVariableDel(Symbol()+teststring+"-Phantom Sell");

	bool cut_the_buy = false;
	bool cut_the_sell = false;
	if (pip_step!=2)
     {
      if (lastbuyticket>0 && ArraySize(Buys)<max_levels && CANDLE_BUY_ACTIVE())
        {
         double next_pip_step = GetPipStep();
         if (ArraySize(Buys)>1 && pip_step_multiplier!=1 && GlobalVariableGet(Symbol()+teststring+"-PSM-BUY")<=0)
            next_pip_step*=((ArraySize(Buys)-1)*pip_step_multiplier);
         if (GlobalVariableGet(Symbol()+teststring+"-PSM-BUY")>0)
           {
            int str_lvls = psm_interval;
            if (str_lvls<=0)
               str_lvls = 1;
            int lvls = (int) ( (ArraySize(Buys)-GlobalVariableGet(Symbol()+teststring+"-PSM-BUY"))/str_lvls);
            for(int v = 1; v<=lvls; v++)
               next_pip_step*=psm_multiplier;
           }

         o_position.SelectByTicket(lastbuyticket);
         // OrderSelect(lastbuyticket, SELECT_BY_TICKET);
         if (Ask<=o_position.PriceOpen()-next_pip_step && (pip_step==0 || pip_step==1))
           {
            cut_the_buy = true;
            double sl = 0;
            if (stop_loss_each_trade>0)
               sl = Ask-(stop_loss_each_trade*Point());
            double the_lots = GetNewLevelLots("BUY", ArraySize(Buys), Buys[ArraySize(Buys)-1]);
            if (GlobalVariableGet(Symbol()+teststring+"-Chop BUY")>0)
              {
               ChopBuys();
              }
            else
              {
               // if (!OrderSend(Symbol(), OP_BUY, the_lots, Ask, 10, sl, 0, "", mn, 0, clrNONE))
               //   Print("OrderSend Error: "+IntegerToString(GetLastError()));

               if (CheckEntryDelay()){
                  o_trade.Buy(the_lots, Symbol(), Ask, sl, 0, "");
                  LastOrderTime = TimeCurrent();

               }
              }
           }
         if (Ask<=lowestbuy-next_pip_step && pip_step==3)
           {
            cut_the_buy = true;
            double sl = 0;
            if (stop_loss_each_trade>0)
               sl = Ask-(stop_loss_each_trade*Point());
            double the_lots = GetNewLevelLots("BUY", ArraySize(Buys), Buys[ArraySize(Buys)-1]);
            if (GlobalVariableGet(Symbol()+teststring+"-Chop BUY")>0)
              {
               ChopBuys();
              }
            else
              {
               // if (!OrderSend(Symbol(), OP_BUY, the_lots, Ask, 10, sl, 0, "", mn, 0, clrNONE))
               //   Print("OrderSend Error: "+IntegerToString(GetLastError()));
               if (CheckEntryDelay()){
                  o_trade.Buy(the_lots, Symbol(), Ask, sl, 0, "");
                  LastOrderTime = TimeCurrent();
               }
              }
           }
         if (Ask>=highestbuy+next_pip_step && pip_step==3)
           {
            cut_the_buy = true;
            double sl = 0;
            if (stop_loss_each_trade>0)
               sl = Ask-(stop_loss_each_trade*Point());
            double the_lots = GetNewLevelLots("BUY", ArraySize(Buys), Buys[ArraySize(Buys)-1]);
            if (GlobalVariableGet(Symbol()+teststring+"-Chop BUY")>0)
              {
               ChopBuys();
              }
            else
              {
               // if (!OrderSend(Symbol(), OP_BUY, the_lots, Ask, 10, sl, 0, "", mn, 0, clrNONE))
               //   Print("OrderSend Error: "+GetLastError());
               if (CheckEntryDelay()){
                  o_trade.Buy(the_lots, Symbol(), Ask, sl, 0, "");
                  LastOrderTime = TimeCurrent();
               }
              }
           }
        }
      if (lastsellticket>0 && ArraySize(Sells)<max_levels && CANDLE_SELL_ACTIVE())
        {
         double next_pip_step = GetPipStep();
         if (ArraySize(Sells)>1 && pip_step_multiplier!=1 && GlobalVariableGet(Symbol()+teststring+"-PSM-BUY")<=0)
            next_pip_step*=((ArraySize(Sells)-1)*pip_step_multiplier);

         if (GlobalVariableGet(Symbol()+teststring+"-PSM-SELL")>0)
           {
            int str_lvls = psm_interval;
            if (str_lvls<=0)
               str_lvls = 1;
            int lvls = (int) ((ArraySize(Sells)-GlobalVariableGet(Symbol()+teststring+"-PSM-SELL"))/str_lvls);
            for(int v = 1; v<=lvls; v++)
               next_pip_step*=psm_multiplier;
           }

         o_position.SelectByTicket(lastsellticket);
         // OrderSelect(lastsellticket, SELECT_BY_TICKET);
         if (Bid>=o_position.PriceOpen()+next_pip_step && (pip_step==0 || pip_step==1))
           {
            cut_the_sell = true;
            double sl = 0;
            if (stop_loss_each_trade>0)
               sl = Bid+(stop_loss_each_trade*Point());
            double the_lots = GetNewLevelLots("SELL", ArraySize(Sells), Sells[ArraySize(Sells)-1]);
            if (GlobalVariableGet(Symbol()+teststring+"-Chop SELL")>0)
              {
               ChopSells();
              }
            else
              {
               // if (!OrderSend(Symbol(), OP_SELL, the_lots, Bid, 10, sl, 0, "", mn, 0, clrNONE))
               //   Print("OrderSend Error: "+GetLastError());
               if (CheckEntryDelay()){
                  o_trade.Sell(the_lots, Symbol(), Bid, sl, 0, "");
                  LastOrderTime = TimeCurrent();
               }
              }
           }
         if (Bid<=lowestsell-next_pip_step && pip_step==3)
           {
            cut_the_sell = true;
            double sl = 0;
            if (stop_loss_each_trade>0)
               sl = Bid+(stop_loss_each_trade*Point());
            double the_lots = GetNewLevelLots("SELL", ArraySize(Sells), Sells[ArraySize(Sells)-1]);
            if (GlobalVariableGet(Symbol()+teststring+"-Chop SELL")>0)
              {
               ChopSells();
              }
            else
              {
               // if (!OrderSend(Symbol(), OP_SELL, the_lots, Bid, 10, sl, 0, "", mn, 0, clrNONE))
               //   Print("OrderSend Error: "+GetLastError());
               if (CheckEntryDelay()){
                  o_trade.Sell(the_lots, Symbol(), Bid, sl, 0, "");
                  LastOrderTime = TimeCurrent();
               }
              }
           }
         if (Bid>=highestsell+next_pip_step && pip_step==3)
           {
            cut_the_sell = true;
            double sl = 0;
            if (stop_loss_each_trade>0)
               sl = Bid+(stop_loss_each_trade*Point());
            double the_lots = GetNewLevelLots("SELL", ArraySize(Sells), Sells[ArraySize(Sells)-1]);
            if (GlobalVariableGet(Symbol()+teststring+"-Chop SELL")>0)
              {
               ChopSells();
              }
            else
              {
               // if (!OrderSend(Symbol(), OP_SELL, the_lots, Bid, 10, sl, 0, "", mn, 0, clrNONE))
               //   Print("OrderSend Error: "+GetLastError());
               if (CheckEntryDelay()){
                  o_trade.Sell(the_lots, Symbol(), Bid, sl, 0, "");
                  LastOrderTime = TimeCurrent();
               }
              }
           }
        }
     }
	if (pip_step==2)
     {
      if (TimeCurrent()>=lastbuytime+(pip_step_amount*60) && (trade_direction== 0 || trade_direction==2) && CANDLE_BUY_ACTIVE())
        {
         cut_the_buy = true;
         double sl = 0;
         if (stop_loss_each_trade>0)
            sl = Ask-(stop_loss_each_trade*Point());
         double the_lots = 0;
         if (ArraySize(Buys)>0)
            the_lots = GetNewLevelLots("BUY", ArraySize(Buys), Buys[ArraySize(Buys)-1]);
         if (GlobalVariableGet(Symbol()+teststring+"-Chop BUY")>0)
           {
            ChopBuys();
           }
         else
           {
            // if (!OrderSend(Symbol(), OP_BUY, the_lots, Ask, 10, sl, 0, "", mn, 0, clrNONE))
            //   Print("OrderSend Error: "+GetLastError());
            if (CheckEntryDelay()){
               o_trade.Buy(the_lots, Symbol(), Bid, sl, 0, "");
               LastOrderTime = TimeCurrent();
            }
           }
        }
      if (TimeCurrent()>=lastselltime+(pip_step_amount*60) && (trade_direction== 1 || trade_direction==2) && CANDLE_SELL_ACTIVE())
        {
         cut_the_sell = true;
         double sl = 0;
         if (stop_loss_each_trade>0)
            sl = Bid+(stop_loss_each_trade*Point());
         double the_lots = 0;
         if (ArraySize(Sells)>0)
            the_lots = GetNewLevelLots("SELL", ArraySize(Sells), Sells[ArraySize(Sells)-1]);
         if (GlobalVariableGet(Symbol()+teststring+"-Chop SELL")>0)
           {
            ChopSells();
           }
         else
           {
            // if (!OrderSend(Symbol(), OP_SELL, the_lots, Bid, 10, sl, 0, "", mn, 0, clrNONE))
            //   Print("OrderSend Error: "+GetLastError());
            if (CheckEntryDelay()){
               o_trade.Sell(the_lots, Symbol(), Bid, sl, 0, "");
               LastOrderTime = TimeCurrent();
            }
           }
        }
     }
	if (use_cut_mode)
     {
      if (GlobalVariableGet(Symbol()+teststring+"-Buy CUT")>0 && cut_the_buy)
        {
//         OrderSelect(cut_buy, SELECT_BY_TICKET);
//         OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 10, clrNONE);

         o_position.SelectByTicket(cut_buy);
         o_trade.PositionClose(o_position.Ticket());
        }
      if (GlobalVariableGet(Symbol()+teststring+"-Sell CUT")>0 && cut_the_sell)
        {
//         OrderSelect(cut_sell, SELECT_BY_TICKET);
//         OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 10, clrNONE);

         o_position.SelectByTicket(cut_sell);
         o_trade.PositionClose(o_position.Ticket());

        }
     }
}
// +------------------------------------------------------------------+
// |                                                                  |
// +------------------------------------------------------------------+
void CloseAllTrades()
{
    for(int v = PositionsTotal()-1; v>=0; v--)
    {
        if (!o_position.SelectByIndex(v))
        {
            break;
        }
        if (o_position.Magic()==mn)
        {
            o_trade.PositionClose(o_position.Ticket());
        }
    }
    Print("EP HIT: All trades closed due to Equity Protector!");
}

// +------------------------------------------------------------------+
// |                                                                  |
// +------------------------------------------------------------------+

void CheckNewPhantomLevels()
{
	int Buys = 0;
	int Sells = 0;

	double highestbuy = 0;
	double highestsell = 0;
	double lowestbuy = 10000000;
	double lowestsell = 10000000;
	for(int i = ObjectsTotal(0)-1; i>=0; i--)
     {
      double price = ObjectGetDouble(0, ObjectName(0, i), OBJPROP_PRICE, 0);
      if (StringFind(ObjectName(0, i),"Phantom Buy", 0)>=0 && StringFind(ObjectName(0, i),"Phantom Buy TP", 0)<0)
        {
         Buys++;
         if (price>highestbuy)
            highestbuy = price;
         if (price<lowestbuy)
            lowestbuy = price;
        }
      if (StringFind(ObjectName(0, i),"Phantom Sell", 0)>=0 && StringFind(ObjectName(0, i),"Phantom Sell TP", 0)<0)
        {
         Sells++;
         if (price>highestsell)
            highestsell = price;
         if (price<lowestsell)
            lowestsell = price;
        }
     }
	phantom_buys = Buys;
	phantom_sells = Sells;

	double Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
	double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

	if((Ask<=lowestbuy-phantom_pip_step*Point() || Buys<=0) && Buys<phantom_levels && GlobalVariableGet(Symbol()+teststring+"-Phantom Buy")<=0)
     {
      // Print("BUY");
      string name = "Phantom Buy "+IntegerToString(Buys+1);
      ObjectCreate(0, name, OBJ_HLINE, 0, TimeCurrent(), Ask);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
     }
	if((Bid>=highestsell+phantom_pip_step*Point() || Sells<=0) && Sells<phantom_levels && GlobalVariableGet(Symbol()+teststring+"-Phantom Sell")<=0)
     {
      // Print("SELL");
      string name = "Phantom Sell "+IntegerToString(Sells+1);
      ObjectCreate(0, name, OBJ_HLINE, 0, TimeCurrent(), Bid);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
     }
	if((Ask<=lowestbuy-phantom_pip_step*Point()) && Buys>=phantom_levels)
     {
      ObjectsDeleteAll(0,"Phantom Buy");
      if (phantom_direction==0)
         GlobalVariableSet(Symbol()+teststring+"-Phantom Buy", 1);
      if (phantom_direction==1)
         GlobalVariableSet(Symbol()+teststring+"-Phantom Sell", 1);
     }
	if((Bid>=highestsell+phantom_pip_step*Point()) && Sells>=phantom_levels)
     {
      ObjectsDeleteAll(0,"Phantom Sell");
      if (phantom_direction==0)
         GlobalVariableSet(Symbol()+teststring+"-Phantom Sell", 1);
      if (phantom_direction==1)
         GlobalVariableSet(Symbol()+teststring+"-Phantom Buy", 1);
     }
}

double GetNewLevelLots(string dir, int level, double s_lots) {
    double increment = 0.01; // change this to the minimum increment allowed by your broker

    if (dir == "BUY") {
        if (GlobalVariableGet(Symbol()+teststring+"-LMM-BUY") > 0) {
            double last_lot = 0;
            datetime lastopen = 0;
            for (int i = PositionsTotal()-1; i >= 0; i--) {
                if (!o_position.SelectByIndex(i)) { break; }

                if (o_position.Symbol() == Symbol() && o_position.Magic() == mn) {
                    if (o_position.Time() > lastopen && o_position.PositionType() == POSITION_TYPE_BUY && dir == "BUY") {
                        lastopen = o_position.Time();
                        last_lot = o_position.Volume();
                    }
                    if (o_position.Time() > lastopen && o_position.PositionType() == POSITION_TYPE_SELL && dir == "SELL") {
                        lastopen = o_position.Time();
                        last_lot = o_position.Volume();
                    }
                }
            }

            if (dir == "BUY" && GlobalVariableGet(Symbol()+teststring+"-LMM-BUY") > 0) {
                last_lot *= lmm_multipler;
            }
            if (dir == "SELL" && GlobalVariableGet(Symbol()+teststring+"-LMM-SELL") > 0) {
                last_lot *= lmm_multipler;
            }
            if (dir == "BUY" && GlobalVariableGet(Symbol()+teststring+"-LMM-BUY") <= 0) {
                last_lot *= lots_multiplier;
            }
            if (dir == "SELL" && GlobalVariableGet(Symbol()+teststring+"-LMM-SELL") <= 0) {
                last_lot *= lots_multiplier;
            }

            // Round the calculated lot size to the nearest allowed increment
            last_lot = MathRound(last_lot / increment) * increment;

            if (last_lot > max_lot_size) {
                last_lot = max_lot_size;
            }
            if (last_lot < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) {
                last_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
            }

            return last_lot;
        } else {
            double ss_lots = s_lots;
            level /= lots_multiplier_interval;

            for (int l = 1; l <= level; l++) {
                ss_lots *= lots_multiplier;
            }

            // Round the calculated lot size to the nearest allowed increment
            ss_lots = MathRound(ss_lots / increment) * increment;

            if (ss_lots > max_lot_size) {
                ss_lots = max_lot_size;
            }

            return ss_lots;
        }
    }

    if (dir == "SELL") {
        if (GlobalVariableGet(Symbol()+teststring+"-LMM-SELL") > 0) {
            double last_lot = 0;
            datetime lastopen = 0;

            for (int i = PositionsTotal()-1; i >= 0; i--) {
                if (!o_position.SelectByIndex(i)) { break; }

                if (o_position.Symbol() == Symbol() && o_position.Magic() == mn) {
                    if (o_position.Time() > lastopen && o_position.PositionType() == POSITION_TYPE_BUY && dir == "BUY") {
                        lastopen = o_position.Time();
                        last_lot = o_position.Volume();
                    }
                    if (o_position.Time() > lastopen && o_position.PositionType() == POSITION_TYPE_SELL && dir == "SELL") {
                        lastopen = o_position.Time();
                        last_lot = o_position.Volume();
                    }
                }
            }

            if (dir == "BUY" && GlobalVariableGet(Symbol()+teststring+"-LMM-BUY") > 0) {
                last_lot *= lmm_multipler;
            }
            if (dir == "SELL" && GlobalVariableGet(Symbol()+teststring+"-LMM-SELL") > 0) {
                last_lot *= lmm_multipler;
            }
            if (dir == "BUY" && GlobalVariableGet(Symbol()+teststring+"-LMM-BUY") <= 0) {
                last_lot *= lots_multiplier;
            }
            if (dir == "SELL" && GlobalVariableGet(Symbol()+teststring+"-LMM-SELL") <= 0) {
                last_lot *= lots_multiplier;
            }

            // Round the calculated lot size to the nearest allowed increment
            last_lot = MathRound(last_lot / increment) * increment;

            if (last_lot > max_lot_size) {
                last_lot = max_lot_size;
            }
            if (last_lot < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) {
                last_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
            }

            return last_lot;
        } else {
            double ss_lots = s_lots;
            level /= lots_multiplier_interval;

            for (int l = 1; l <= level; l++) {
                ss_lots *= lots_multiplier;
            }

            // Round the calculated lot size to the nearest allowed increment
            ss_lots = MathRound(ss_lots / increment) * increment;

            if (ss_lots > max_lot_size) {
                ss_lots = max_lot_size;
            }

            return ss_lots;
        }
    }

    return 0.01;
}

// +------------------------------------------------------------------+
double GetPipStep()
{
	if (pip_step==0 || pip_step==3)
      return (pip_step_amount*Point());

	if (pip_step==1)
     {
      double atrH1 = GetValue(hatrH1);// iATR(Symbol(), PERIOD_H1, 3, 0);
      double atrH4 = GetValue(hatrH4);// iATR(Symbol(), PERIOD_H4, 3, 0);
      double atrD1 = GetValue(hatrD1);// iATR(Symbol(), PERIOD_D1, 3, 0);
      double atrW1 = GetValue(hatrW1);// iATR(Symbol(), PERIOD_W1, 3, 0);
      double avg = (atrH1+atrH4+atrD1+atrW1)/4;
      return (avg/pip_step_amount);
     }

	return (pip_step_amount)*Point();
}
// +------------------------------------------------------------------+
// Declare the last_trade_time variable
// +------------------------------------------------------------------+
datetime last_trade_time = 0; // Variable to store the timestamp of the last trade

bool IsTimeBetweenTradesElapsed()
{
    // If time restriction is set to zero, or less than 3 positions have been opened, allow trading
    if (time_between_trades_minutes <= 0 || opened_positions < 2)
        return true;

    datetime currentTime = TimeCurrent();
    int minutesPassed = (int)(currentTime - last_trade_time) / 60;

    return minutesPassed >= time_between_trades_minutes;
}

// +------------------------------------------------------------------+

// +------------------------------------------------------------------+
bool IsUptrend()
{
    if (!USE_MA)  // If MA is turned off
        return false;  // No uptrend

    double close = iClose(Symbol(), 0, 0);
    double ma1 = GetValue(hma1, 1);// iMA(Symbol(), EMA_Timeframe_Filter, ma1_period, 0, ma1_method, PRICE_CLOSE, 1);
    double ma2 = GetValue(hma2, 1);// iMA(Symbol(), EMA_Timeframe_Filter, ma2_period, 0, ma2_method, PRICE_CLOSE, 1);
    double ma3 = GetValue(hma3, 1);// iMA(Symbol(), EMA_Timeframe_Filter, ma3_period, 0, ma3_method, PRICE_CLOSE, 1);

    // Returns true if the condition for uptrend is met.
    return (close > ma1 && ma1 > ma2 && ma2 > ma3);
}



bool IsPriceCrossingMA()
{
    if (!USE_PRICE_CROSSING_MA) // If input is false, don't check for MA crossing
        return true;

    double Close = iClose(Symbol(), 0, 0);
    double MA = GetValue(hma1, 0);// iMA(Symbol(), EMA_Timeframe_Filter, ma1_period, 0, ma1_method, PRICE_CLOSE, 0);
    double PrevClose = iClose(Symbol(), 0, 1);
    double PrevMA = GetValue(hma1, 1);// iMA(Symbol(), EMA_Timeframe_Filter, ma1_period, 0, ma1_method, PRICE_CLOSE, 1);

    if (MA_Entry_Direction == 1 && Close < MA && PrevClose > PrevMA)
    {
        // Do not place a trade
        return false;
    }
    if (MA_Entry_Direction == -1 && Close > MA && PrevClose < PrevMA)
    {
        // Do not place a trade
        return false;
    }
    return true;
}


bool MA_BUY_ENTRY()
{
    if (!USE_MA)
        return false;

    if (!IsPriceCrossingMA())
        return false;

    if (MA_Entry_Direction == 1 || MA_Entry_Direction == -1) // Trading with the trend
    {
        double Close = iClose(Symbol(), 0, 0);
        double FastMA = GetValue(hma1, 0);
        double MediumMA = GetValue(hma2, 0);
        double SlowMA = GetValue(hma3, 0);

        if (SlowMA >= FastMA && SlowMA <= MediumMA)
            return false; // SlowMA is between FastMA and MediumMA, no trades taken

        // The rest of your function code...
        if (use_ma1 && !use_ma2 && !use_ma3)
        {
            last_trade_time = TimeCurrent(); // Update last_trade_time
            opened_positions++; // Increment the number of opened positions
            return true;
        }
        if (use_ma1 && use_ma2 && !use_ma3)
        {
            last_trade_time = TimeCurrent(); // Update last_trade_time
            opened_positions++; // Increment the number of opened positions
            return true;
        }
        if (use_ma1 && use_ma2 && use_ma3)
        {
            if (FastMA > SlowMA && MediumMA > SlowMA)
            {
                last_trade_time = TimeCurrent(); // Update last_trade_time
                opened_positions++; // Increment the number of opened positions
                return true;
            }
        }
    }
    return false;
}


bool MA_SELL_ENTRY()

{

    if (!USE_MA)
        return false;

    if (!IsPriceCrossingMA())
        return false;

      if (MA_Entry_Direction == -1 || MA_Entry_Direction == 1) // Trading against the trend
    {
        double Close = iClose(Symbol(), 0, 0);
        double FastMA = GetValue(hma1, 0);
        double MediumMA = GetValue(hma2, 0);
        double SlowMA = GetValue(hma3, 0);

        if (SlowMA >= FastMA && SlowMA <= MediumMA)
            return false; // SlowMA is between FastMA and MediumMA, no trades taken

        // The rest of your function code...
        if (use_ma1 && !use_ma2 && !use_ma3)
        {
            last_trade_time = TimeCurrent(); // Update last_trade_time
            opened_positions++; // Increment the number of opened positions
            return true;
        }
        if (use_ma1 && use_ma2 && !use_ma3)
        {
            last_trade_time = TimeCurrent(); // Update last_trade_time
            opened_positions++; // Increment the number of opened positions
            return true;
        }
        if (use_ma1 && use_ma2 && use_ma3)
        {
            if ((GetValue(hma2, 0) < GetValue(hma3, 0) ))
            {
                last_trade_time = TimeCurrent(); // Update last_trade_time
                opened_positions++; // Increment the number of opened positions
                return true;
            }
        }
    }
    return false;
}



bool RSI_BUY()
{
    if (!use_rsi_filter)
        return true;

    if (RSI_Trend_Filter == 1) // Trading with the trend
    {
        if (GetValue(hRSI, 0) >= rsi_upper)
        {
            last_trade_time = TimeCurrent(); // Update last_trade_time
            opened_positions++; // Increment the number of opened positions
            return true; // Allow trading
        }
    }
    else if (RSI_Trend_Filter == -1) // Trading against the trend
    {
        if (GetValue(hRSI, 0) <= rsi_lower)
        {
            last_trade_time = TimeCurrent(); // Update last_trade_time
            opened_positions++; // Increment the number of opened positions
            return true; // Allow trading
        }
    }
    return false;
}

bool RSI_SELL()
{
    if (!use_rsi_filter)
        return true;

    if (RSI_Trend_Filter == 1) // Trading with the trend
    {
        if (GetValue(hRSI, 0) <= rsi_lower)
        {
            last_trade_time = TimeCurrent(); // Update last_trade_time
            opened_positions++; // Increment the number of opened positions
            return true; // Allow trading
        }
    }
    else if (RSI_Trend_Filter == -1) // Trading against the trend
    {
        if (GetValue(hRSI, 0) >= rsi_upper)
        {
            last_trade_time = TimeCurrent(); // Update last_trade_time
            opened_positions++; // Increment the number of opened positions
            return true; // Allow trading
        }
    }
    return false;
}
CTrade Trade;

bool ADX_BUY_ENTRY()
{
    if (!use_adx_filter) // If the ADX filter is not activated
        return true; // Allow trading

    // Calculate the ADX value
    double adxValue = iADX(Symbol(), ADX_Timeframe, ADX_Period);

    // Allow trading if the ADX value is below the maximum threshold
    if (adxValue < ADX_Max_Value)
    {
        return true;
    }

    // Handle the max value action
    if (ADX_Max_Value_Action == PAUSE_START_TRADES)
    {
        // Pause opening new trades
        return false;
    }
    else if (ADX_Max_Value_Action == CLOSE_ALL_TRADES)
    {
        // Close all trades
        for (int i = PositionsTotal() - 1; i >= 0; i--)
        {
            if (!o_position.SelectByIndex(i)) { break; }
            if (o_position.Magic() == mn && o_position.Symbol() == Symbol())
            {
                // Close the selected position
                Trade.PositionClose(o_position.Ticket());
            }
        }
    }

    return false; // Otherwise, do not allow trading
}

bool ADX_SELL_ENTRY()
{
    if (!use_adx_filter) // If the ADX filter is not activated
        return true; // Allow trading

    // Calculate the ADX value
    double adxValue = iADX(Symbol(), ADX_Timeframe, ADX_Period);

    // Allow trading if the ADX value is below the maximum threshold
    if (adxValue < ADX_Max_Value)
    {
        return true;
    }

    // Handle the max value action
    if (ADX_Max_Value_Action == PAUSE_START_TRADES)
    {
        // Pause opening new trades
        return false;
    }
    else if (ADX_Max_Value_Action == CLOSE_ALL_TRADES)
    {
        // Close all trades
        for (int i = PositionsTotal() - 1; i >= 0; i--)
        {
            if (!o_position.SelectByIndex(i)) { break; }
            if (o_position.Magic() == mn && o_position.Symbol() == Symbol())
            {
                // Close the selected position
                Trade.PositionClose(o_position.Ticket());
            }
        }
    }

    return false; // Otherwise, do not allow trading
}

// +------------------------------------------------------------------+
bool SPREAD_GO()
{
	if ( SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) <= max_spread)
      return true;

	return false;
}
// +------------------------------------------------------------------+
void ManageTP_BUYS()
{
	double lots[], opens[], opentrades = 0;
	for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if (!o_position.SelectByIndex(i)) {break;}
      if (o_position.Magic()==mn && o_position.Symbol()==Symbol() && o_position.PositionType()==OP_BUY)
        {
         opentrades++;
         ArrayResize(lots, ArraySize(lots)+1, 0);
         ArrayResize(opens, ArraySize(opens)+1, 0);
         lots[ArraySize(lots)-1]=o_position.Volume();
         opens[ArraySize(opens)-1]=o_position.PriceOpen();
        }
     }
	if (opentrades>=1)
     {
      double numerator = 0, denominator = 0;
      for(int j = ArraySize(lots)-1; j>=0; j--)
        {
         // Print(opens[j]);
         numerator += (lots[j]*opens[j]);
         denominator += lots[j];
        }
      double NewTP = 0;
      if (denominator != 0)
      NewTP = (numerator/denominator)+(tp_all_trades*Point());


      if (GlobalVariableGet(Symbol()+teststring+"-TPM-BUY")>0)
        {
         int tpm_levels = (int)(opentrades-tp_manager_start);
         NewTP = (numerator/denominator)+(tp_manager_new_tp*Point());

         for(int v = 0; v<(tpm_levels/tp_manager_interval); v++)
           {
            NewTP-=(tp_manager_increment*Point());
           }
        }
      int first_buy = (int) GlobalVariableGet(Symbol()+teststring+"-First Buy");
      bool buy_trail_active = GlobalVariableGet(Symbol()+teststring+"-Trail Active Buy")>=1;
      for(int u = PositionsTotal()-1; u>=0; u--)
        {
         if (!o_position.SelectByIndex(u)) {break;}

         if (o_position.Magic()==mn && o_position.Symbol()==Symbol() && o_position.PositionType()==POSITION_TYPE_BUY)
           {
            if (!buy_trail_active || (buy_trail_active && o_position.Ticket()!=first_buy))
              {
               if (MathAbs(o_position.TakeProfit()-NewTP)>Point())
                 {
                  ModifyTakeProfit(NewTP);
                 }
              }
            else
              {
               if (o_position.TakeProfit()!=0)
                  ModifyTakeProfit(0);
              }
           }
        }
     }
}
// +------------------------------------------------------------------+
void ManageTP_SELLS()
{
	double lots[], opens[], opentrades = 0;
	for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if (!o_position.SelectByIndex(i)) {break;}
      if (o_position.Magic()==mn && o_position.Symbol()==Symbol() && o_position.PositionType()==POSITION_TYPE_SELL)
        {
         opentrades++;
         ArrayResize(lots, ArraySize(lots)+1, 0);
         ArrayResize(opens, ArraySize(opens)+1, 0);
         lots[ArraySize(lots)-1]    = o_position.Volume();
         opens[ArraySize(opens)-1]  = o_position.PriceOpen();
        }
     }
	if (opentrades>=1)
     {
      double numerator = 0, denominator = 0;
      for(int j = ArraySize(lots)-1; j>=0; j--)
        {
         // Print(opens[j]);
         numerator += (lots[j]*opens[j]);
         denominator += lots[j];
        }
      double NewTP;
      NewTP = (numerator/denominator)-(tp_all_trades*Point());

      if (GlobalVariableGet(Symbol()+teststring+"-TPM-SELL")>0)
        {
         int tpm_levels = (int)(opentrades-tp_manager_start);
         NewTP = (numerator/denominator)-(tp_manager_new_tp*Point());

         for(int v = 0; v<(tpm_levels/tp_manager_interval); v++)
           {
            NewTP += (tp_manager_increment*Point());
           }
        }

      int first_sell = (int)GlobalVariableGet(Symbol()+teststring+"-First Sell");
      bool sell_trail_active = GlobalVariableGet(Symbol()+teststring+"-Trail Active Sell")>=1;
      for(int u = PositionsTotal()-1; u>=0; u--)
        {
         if (!o_position.SelectByIndex(u))
           {
            break;
           }
         if (o_position.Magic()==mn && o_position.Symbol()==Symbol() && o_position.PositionType()==POSITION_TYPE_SELL)
           {
            if (!sell_trail_active ||
               (sell_trail_active && (o_position.Ticket()!=first_sell && trail_stop_type==start_trades))
              )
              {
               if (MathAbs(o_position.TakeProfit()-NewTP)>Point())
                 {
                  ModifyTakeProfit(NewTP);
                 }
              }
            else
              {
               if (o_position.TakeProfit()!=0)
                  ModifyTakeProfit(0);
              }
           }
        }
     }
}
// +------------------------------------------------------------------+
// |                                                                  |
// +------------------------------------------------------------------+
void CheckAccountTP()
{
	if (AccountEquity()>=acc_tp)
     {
      GlobalVariableSet(Symbol()+teststring+"-PAUSE-BUY", 1);
      GlobalVariableSet(Symbol()+teststring+"-PAUSE-SELL", 1);
      for(int i =PositionsTotal()-1; i>=0; i--)
        {
         if (!o_position.SelectByIndex(i))
           {
            break;
           }
         if (o_position.Magic()==mn)
           {
            // if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 10, clrNONE)) Print("OrderClose Error: "+GetLastError());

               o_trade.PositionClose(o_position.Ticket());
           }
        }
      int opens = 0;
      for(int i =PositionsTotal()-1; i>=0; i--)
        {
         if (!o_position.SelectByIndex(i))
           {
            break;
           }
         if (o_position.Magic()==mn)
           {
            opens++;
           }
        }
      if (GlobalVariableGet("GEN"+teststring+"-ACC_TP_HIT")<=0)
         Alert("Account TP Hit!");
      GlobalVariableSet("GEN"+teststring+"-ACC_TP_HIT", 1);
      m_acc_tp_reset_button.Color(clrGreen);
      ExpertRemove();
     }
}
// +------------------------------------------------------------------+
void CheckFloatingBucket()
{
    double profit = 0;

    if (PositionsTotal() > 0)
    {
        for (int i = PositionsTotal() - 1; i >= 0; i--)
        {
            if (!o_position.SelectByIndex(i))
            {
                break;
            }

            if (o_position.Magic() == mn && o_position.Symbol() == Symbol())
            {
                profit += o_position.Profit() + o_position.Commission() + o_position.Swap();
            }
        }
    }

    double new_fb_goal = fb_goal;
    int levels;

    if (GlobalVariableGet(Symbol() + teststring + "-FBM") > 0)
    {
        new_fb_goal = fbm_new_goal;
        double diff = MathAbs(fbm_start + profit);
        if (fbm_interval > 0)
        {
            levels = (int)(diff / fbm_interval);
            for (int i = 1; i < levels; i++)
            {
                new_fb_goal -= fbm_increment;
            }
        }
        if (new_fb_goal > GlobalVariableGet(Symbol() + teststring + "-FBM-Goal"))
        {
            new_fb_goal = GlobalVariableGet(Symbol() + teststring + "-FBM-Goal");
        }
        else
        {
            GlobalVariableSet(Symbol() + teststring + "-FBM-Goal", new_fb_goal);
        }
    }

    if (fb_start > 0)
    {
        if (profit >= fb_start)
        {
            if (profit > GlobalVariableGet(Symbol() + teststring + "MR-Trail-HWM"))
            {
                GlobalVariableSet(Symbol() + teststring + "MR-Trail-HWM", profit);
            }
        }
        else
        {
            GlobalVariableSet(Symbol() + teststring + "MR-Trail-HWM", 0);
        }
    }

    double floatingProfitPercent = (profit / AccountBalance()) * 100;
    bool isGoalReached = false;

    if (fb_type == pair)
    {
        if (profit >= new_fb_goal)
        {
            isGoalReached = true;
        }
        else if (fb_start > 0 && GlobalVariableGet(Symbol() + teststring + "MR-Trail-HWM") > 0 &&
                 profit <= (GlobalVariableGet(Symbol() + teststring + "MR-Trail-HWM") - fb_stop))
        {
            isGoalReached = true;
        }
    }
    else if (fb_type == account_dollar)
    {
        if (profit >= new_fb_goal || (fb_start > 0 && GlobalVariableGet(Symbol() + teststring + "MR-Trail-HWM") > 0 &&
                                      profit <= (GlobalVariableGet(Symbol() + teststring + "MR-Trail-HWM") - fb_stop)))
        {
            isGoalReached = true;
        }
    }
    else if (fb_type == account_perc)
    {
        if (floatingProfitPercent >= new_fb_goal || (fb_start > 0 &&
            GlobalVariableGet(Symbol() + teststring + "MR-Trail-HWM") > 0 &&
            profit <= (GlobalVariableGet(Symbol() + teststring + "MR-Trail-HWM") - fb_stop)))
        {
            isGoalReached = true;
        }
    }

    if (isGoalReached)
    {
        GlobalVariableSet(Symbol() + teststring + "MR-Trail-HWM", 0);
        GlobalVariableDel(Symbol() + teststring + "-FBM");
        GlobalVariableDel(Symbol() + teststring + "-FBM-Goal");
        GlobalVariableSet(Symbol() + teststring + "-PAUSE-BUY", 1);
        GlobalVariableSet(Symbol() + teststring + "-PAUSE-SELL", 1);

        for (int i = PositionsTotal() - 1; i >= 0; i--)
        {
            if (!o_position.SelectByIndex(i))
            {
                break;
            }

            if (o_position.Magic() == mn && o_position.Symbol() == Symbol())
            {
                o_trade.PositionClose(o_position.Ticket());
            }
        }

        if (!fb_auto_reset)
        {
            if (GlobalVariableGet(Symbol() + teststring + "-FB Hit") <= 0)
            {
                Alert("Floating Bucket Hit!");
            }
            GlobalVariableSet(Symbol() + teststring + "-FB Hit", 1);
        }
    }

    string fbLabelText = "";

    if (fb_type == pair)
    {
        fbLabelText = "Floating Bucket: $" + DoubleToString(profit, 2) + " / $" + DoubleToString(new_fb_goal);
    }
    else if (fb_type == account_dollar)
    {
        fbLabelText = "Floating Bucket: $" + DoubleToString(profit, 2) + " / $" + DoubleToString(new_fb_goal);
    }
    else if (fb_type == account_perc)
    {
        fbLabelText = "Floating Bucket: " + DoubleToString(floatingProfitPercent, 2) + "% / " +
                      DoubleToString(new_fb_goal) + "%";
    }

    m_fb_label.Text(fbLabelText);

    if (use_acc_tp && !isGoalReached)
    {
        CheckAccountTP();
    }
}

// +------------------------------------------------------------------+
void CheckDailyGoal()
{
    double profit = 0;

    HistorySelect(iTime(Symbol(), PERIOD_D1, 0), TimeCurrent());

    for(int i = HistoryOrdersTotal() - 1; i >= 0; i--)
    {
        if (!o_history.SelectByIndex(i)){break;}
        if (o_history.Magic() == mn && o_history.TimeDone() >= iTime(Symbol(), PERIOD_D1, 0))
        {
            profit += o_deal.Profit() + o_deal.Commission() + o_deal.Swap();
        }
    }

    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (!o_position.SelectByIndex(i)){break;}
        if (o_position.Magic() == mn)
        {
            profit += o_position.Profit() + o_position.Commission() + o_position.Swap();
        }
    }

    if (use_daily_goal)
    {
        if (daily_goal_type == acc_dollar)
            m_daily_goal_label.Text("Daily Goal: $" + DoubleToString(profit, 2) + " / $" + DoubleToString(daily_goal_amount));
        else if (daily_goal_type == acc_perc)
            m_daily_goal_label.Text("Daily Goal: " + DoubleToString((profit / AccountBalance() * 100), 2) + "% / " + DoubleToString(daily_goal_amount) + "%");
    }
if((profit >= daily_goal_amount && daily_goal_type == acc_dollar) || (profit >= ((AccountBalance() * daily_goal_amount) / 100) && daily_goal_type == acc_perc))

    {
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            if (!o_position.SelectByIndex(i)){break;}
            if (o_position.Magic() == mn)
            {
                o_trade.PositionClose(o_position.Ticket());
            }
        }

        if (GlobalVariableGet(Symbol() + teststring + "-PAUSE-BUY") <= 0)
            Alert("Daily Goal Hit!");

        GlobalVariableSet(Symbol() + teststring + "-PAUSE-BUY", 1);
        GlobalVariableSet(Symbol() + teststring + "-PAUSE-SELL", 1);
        GlobalVariableSet(Symbol() + teststring + "-PAUSE-ACTIVE", 1); // Include this line to also set the -PAUSE-ACTIVE variable
    }
}

// +------------------------------------------------------------------+
void CheckAccountSL()
{
	m_account_sl_label.Text("Account SL: $"+DoubleToString(AccountEquity(), 2)+" / $"+DoubleToString(acc_sl));
	if (AccountEquity()<=acc_sl)
     {
      for(int i =PositionsTotal()-1; i>=0; i--)
        {
         if (!o_position.SelectByIndex(i)) {break;}
         if (o_position.Magic()==mn)
           {
            // if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 10, clrNONE))
            //   Print("OrderClose Error: "+GetLastError());

            o_trade.PositionClose(o_position.Ticket());
           }
        }
      int opens = 0;
      for(int i =PositionsTotal()-1; i>=0; i--)
        {
         if (!o_position.SelectByIndex(i)) {break;}
         if (o_position.Magic()==mn)
           {
            opens++;
           }
        }
      if (GlobalVariableGet("GEN"+teststring+"-ACC_SL_HIT")<=0)
         Alert("Account SL Hit!");
      GlobalVariableSet("GEN"+teststring+"-ACC_SL_HIT", 1);
      m_acc_sl_reset_button.Color(clrGreen);
      ExpertRemove();
     }
}
// +------------------------------------------------------------------+
void OnChartEvent(const int id,         // Event ID
                  const long& lparam,   // Parameter of type long event
                  const double& dparam, // Parameter of type double event
                  const string& sparam) // Parameter of type string events)
{
	m_panel.ChartEvent(id, lparam, dparam, sparam);
	if (id==CHARTEVENT_OBJECT_CLICK)
	{
      if (sparam=="pb_reset_button")
      {
         GlobalVariableDel(Symbol()+teststring+"MR_PB_Start_Time");
         GlobalVariableDel(Symbol()+teststring+"PB_Goal_Reached");
         m_pb_reset_button.Color(clrGray);
      }
      if (sparam=="FB_reset_button")
      {
         GlobalVariableDel(Symbol()+teststring+"-FB Hit");
         GlobalVariableDel("GEN"+teststring+"-FB Hit");
         m_fb_reset_button.Color(clrGray);
      }
      if (sparam=="ep_reset_button")
      {
         GlobalVariableDel(Symbol()+teststring+"-EP Hit");
         m_ep_reset_button.Color(clrGray);
      }
      if (sparam=="acc_tp_reset_button")
      {
         GlobalVariableDel("GEN"+teststring+"-ACC_TP_HIT");
         m_acc_tp_reset_button.Color(clrGray);
      }
      if (sparam=="acc_sl_reset_button")
      {
         GlobalVariableDel("GEN"+teststring+"-ACC_SL_HIT");
         m_acc_sl_reset_button.Color(clrGray);
      }
      if (sparam=="closeall_button")
      {
         if ( PositionsTotal() > 0 )
         {
            for (int i = PositionsTotal() - 1 ; i >= 0 ; i--)
            {
               if (!o_position.SelectByIndex(i)) {break;}
               if (o_position.Symbol() == Symbol())
               {
                  o_trade.PositionClose(o_position.Ticket());
               }
            }
         }
      }
	}
}

void ManagePhantomTP()
{
	int Buys = 0;
	int Sells = 0;

	double highestbuy = 0;
	double highestsell = 0;
	double lowestbuy = 10000000;
	double lowestsell = 10000000;
	for(int i = ObjectsTotal(0)-1; i>=0; i--)
     {
      double price = ObjectGetDouble(0, ObjectName(0, i), OBJPROP_PRICE, 0);
      if (StringFind(ObjectName(0, i),"Phantom Buy", 0)>=0 && StringFind(ObjectName(0, i),"Phantom Buy TP", 0)<0)
        {
         Buys++;
         if (price>highestbuy)
            highestbuy = price;
         if (price<lowestbuy)
            lowestbuy = price;
        }
      if (StringFind(ObjectName(0, i),"Phantom Sell", 0)>=0 && StringFind(ObjectName(0, i),"Phantom Sell TP", 0)<0)
        {
         Sells++;
         if (price>highestsell)
            highestsell = price;
         if (price<lowestsell)
            lowestsell = price;
        }
     }

	double buy_tp = (lowestbuy+((highestbuy-lowestbuy)/2))+(phantom_tp*Point());
	double sell_tp = (lowestsell+((highestsell-lowestsell)/2))-(phantom_tp*Point());

	string buy_name = "Phantom Buy TP";
	string sell_name = "Phantom Sell TP";

	ObjectCreate(0, buy_name, OBJ_HLINE, 0, TimeCurrent(), buy_tp);
	ObjectSetInteger(0, buy_name, OBJPROP_COLOR, clrGreen);
	ObjectSetInteger(0, buy_name, OBJPROP_STYLE, STYLE_DASH);
	ObjectSetDouble(0, buy_name, OBJPROP_PRICE, 0, buy_tp);

	ObjectCreate(0, sell_name, OBJ_HLINE, 0, TimeCurrent(), sell_tp);
	ObjectSetInteger(0, sell_name, OBJPROP_COLOR, clrGreen);
	ObjectSetInteger(0, sell_name, OBJPROP_STYLE, STYLE_DASH);
	ObjectSetDouble(0, sell_name, OBJPROP_PRICE, 0, sell_tp);

	double Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
	double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

	if (Ask<=sell_tp)
      ObjectsDeleteAll(0,"Phantom Sell");
	if (Bid>=buy_tp)
      ObjectsDeleteAll(0,"Phantom Buy");

}
// +------------------------------------------------------------------+
bool MAX_CHARTS()
{
	string charts[];
	for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if (!o_position.SelectByIndex(i)) {break;}
      if (o_position.Magic()==mn)
        {
         if (ArraySize(charts)>0)
           {
            bool found = false;
            for(int c = ArraySize(charts)-1; c>=0; c--)
              {
               if (o_position.Symbol()==charts[c])
                 {
                  found = true;
                  break;
                 }
              }
            if (!found)
              {
               ArrayResize(charts, ArraySize(charts)+1, 0);
               charts[ArraySize(charts)-1]=o_position.Symbol();
              }
           }
         else
           {
            ArrayResize(charts, ArraySize(charts)+1, 0);
            charts[ArraySize(charts)-1]=o_position.Symbol();
           }
        }
     }
	charts_open = ArraySize(charts);
	if (ArraySize(charts)>=max_charts && max_charts>0)
      return false;

	return true;
}
// +------------------------------------------------------------------+
void InitProfitBucket()
{
	if (!GlobalVariableCheck(Symbol()+teststring+"MR_PB_Start_Time"))
     {
      GlobalVariableSet(Symbol()+teststring+"MR_PB_Start_Time", TimeCurrent());
     }
}
// +------------------------------------------------------------------+
void CheckProfitBucket()
{
	double profit = 0;

	datetime t = (datetime) GlobalVariableGet(Symbol()+teststring+"MR_PB_Start_Time");
	HistorySelect(t, TimeCurrent());
	for(int i =HistoryOrdersTotal()-1; i>=0; i--)
     {
      if (!o_history.SelectByIndex(i)){break;}
      if (o_history.Magic()==mn && o_history.Symbol()==Symbol())
        {
         profit += o_deal.Profit() + o_deal.Commission() + o_deal.Swap();
        }
     }


	for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if (!o_position.SelectByIndex(i)) {break;}
      if (
         o_position.Time()>=GlobalVariableGet(Symbol()+teststring+"MR_PB_Start_Time") &&
         o_position.Magic()==mn && o_position.Symbol()==Symbol()
      )
        {
         profit += o_position.Profit()+o_position.Commission()+o_position.Swap();
        }
     }
	profit_bucket = profit;
	if (profit>=profit_bucket_goal)
     {
      if (profit_bucket_auto_reset)
        {
         GlobalVariableDel(Symbol()+teststring+"MR_PB_Start_Time");
        }
      else
         GlobalVariableSet(Symbol()+teststring+"PB_Goal_Reached", 1);
      for(int i =PositionsTotal()-1; i>=0; i--)
        {
         if (!o_position.SelectByIndex(i)) {break;}
         if (o_position.Magic()==mn && o_position.Symbol()==Symbol())
           {
            // if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 10, clrNONE))
            //   Print("OrderClose Error: "+GetLastError());
            o_trade.PositionClose(o_position.Ticket());
           }
        }
     }
}

int DayOfWeek()
{
	MqlDateTime tm;
	TimeCurrent(tm);
	return(tm.day_of_week);
}
// +------------------------------------------------------------------+
double WeekProfitPerc()
{
	datetime startofweek = iTime(Symbol(), PERIOD_D1, DayOfWeek()-1);
	double profit = 0;

	HistorySelect(startofweek, TimeCurrent());
	for(int i =HistoryOrdersTotal()-1; i>=0; i--)
     {
      if (!o_history.SelectByIndex(i)){break;}
      if (o_history.Magic()==mn
      && o_history.TimeDone() >= startofweek
      )
        {
         profit += o_deal.Profit() + o_deal.Commission() + o_deal.Swap();
        }
     }


	for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if (!o_position.SelectByIndex(i)) {break;}
      if (
         o_position.Magic()==mn
      )
        {
         profit += o_position.Profit()+o_position.Commission()+o_position.Swap();
        }
     }
	if (use_weekly_goal)
      m_weekly_label.Text("Weekly Goal: "+DoubleToString((profit/AccountBalance())*100, 2)+"% / "+DoubleToString(weekly_goal_perc)+"%");

	double balance_sow = AccountEquity()-profit;
	if (balance_sow<=0)
      return 0;

	return (profit/balance_sow)*100;
}
// +------------------------------------------------------------------+
void Manage_Trail()
{

	int first_buy = (int)GlobalVariableGet(Symbol()+teststring+"-First Buy");
	int first_sell = (int)GlobalVariableGet(Symbol()+teststring+"-First Sell");

	double Buy_BE = 0, Sell_BE = 0;
	double lots[], opens[], opentrades = 0;
	double s_lots[], s_opens[], s_opentrades = 0;
	for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if (!o_position.SelectByIndex(i)) {break;}
      if((o_position.Ticket()==first_buy || trail_stop_type==all_trades) &&
         o_position.Magic()==mn && o_position.Symbol()==Symbol() && o_position.PositionType()==POSITION_TYPE_BUY)
        {
         opentrades++;
         ArrayResize(lots, ArraySize(lots)+1, 0);
         ArrayResize(opens, ArraySize(opens)+1, 0);
         lots[ArraySize(lots)-1]          = o_position.Volume();
         opens[ArraySize(opens)-1]        = o_position.PriceOpen();
        }
      if((o_position.Ticket()==first_sell || trail_stop_type==all_trades) &&
         o_position.Magic()==mn && o_position.Symbol()==Symbol() && o_position.PositionType()==POSITION_TYPE_SELL)
        {
         s_opentrades++;
         ArrayResize(s_lots, ArraySize(s_lots)+1, 0);
         ArrayResize(s_opens, ArraySize(s_opens)+1, 0);
         s_lots[ArraySize(s_lots)-1]      = o_position.Volume();
         s_opens[ArraySize(s_opens)-1]    = o_position.PriceOpen();
        }
     }
	if (opentrades>=1)
     {
      double numerator = 0, denominator = 0;
      for(int j = ArraySize(lots)-1; j>=0; j--)
        {
         // Print(opens[j]
         numerator += (lots[j]*opens[j]);
         denominator += lots[j];
        }
        if (denominator!=0)
           Buy_BE = (numerator/denominator);
     }
	if (s_opentrades>=1)
     {
      double numerator = 0, denominator = 0;
      for(int j = ArraySize(s_lots)-1; j>=0; j--)
        {
         // Print(opens[j]);
         numerator += (s_lots[j]*s_opens[j]);
         denominator += s_lots[j];
        }
        if (denominator!=0)
            Sell_BE = (numerator/denominator);
     }

	for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if (!o_position.SelectByIndex(i)) {break;}
      if (o_position.Magic()==mn)
        {
         double pBid, pAsk, pp;

         pp = SymbolInfoDouble(o_position.Symbol(), SYMBOL_POINT);
         double NewStop = 0;

         if((o_position.Ticket()==first_buy || trail_stop_type==all_trades) &&
            o_position.PositionType()==POSITION_TYPE_BUY)
           {
            pBid = SymbolInfoDouble(o_position.Symbol(), SYMBOL_BID);

            if (pBid-Buy_BE>trail_stop_start*pp &&
               ((o_position.StopLoss()<pBid -(trail_stop_stop+trail_stop_interval)*pp || o_position.StopLoss()==0))
              )
              {
               NewStop = pBid-trail_stop_stop*pp;
              }

            if (NewStop<o_position.StopLoss())
               NewStop = 0; // new stop can never move below the previous stop

            if (NewStop!=0)
              {
               ModifyStopLoss(NewStop);
               GlobalVariableSet(Symbol()+teststring+"-Trail Active Buy", 1);
              }
           }

         if((o_position.Ticket()==first_sell || trail_stop_type==all_trades) &&
            o_position.PositionType()==POSITION_TYPE_SELL)
           {
            pAsk = SymbolInfoDouble(o_position.Symbol(), SYMBOL_ASK);

            if (Sell_BE-pAsk>trail_stop_start*pp &&
               ((o_position.StopLoss()>pAsk+(trail_stop_stop+trail_stop_interval)*pp || o_position.StopLoss()==0))
              )
               NewStop = pAsk+trail_stop_stop*pp;

            if (NewStop>o_position.StopLoss() && o_position.StopLoss()>0)
               NewStop = 0; // new stop can never move above the previous stop
            if (NewStop!=0)
              {
               ModifyStopLoss(NewStop);
               GlobalVariableSet(Symbol()+teststring+"-Trail Active Sell", 1);
              }
           }
        }
     }
}
// +------------------------------------------------------------------+
void ModifyStopLoss(double ldStopLoss)
{
	bool OrderFlag = OrderModifyReliable((int)o_position.Ticket(), o_position.PriceOpen(), ldStopLoss, o_position.TakeProfit(), 0, CLR_NONE);
}
// +------------------------------------------------------------------+
// |                                                                  |
// +------------------------------------------------------------------+
void ModifyTakeProfit(double ldTakeProfit)
{
	bool OrderFlag = OrderModifyReliable((int)o_position.Ticket(), o_position.PriceOpen(), o_position.StopLoss(), ldTakeProfit, 0, CLR_NONE);
}
// +------------------------------------------------------------------+
bool OrderModifyReliable(int ticket, double price, double stoploss,
                         double takeprofit, datetime expiration,
                         color arrow_color = CLR_NONE)
{
	OrderReliable_Fname = "OrderModifyReliable";

	OrderReliablePrint(" attempted modify of #"+IntegerToString(ticket)+" price:"+DoubleToString(price)+
                      " sl:"+DoubleToString(stoploss)+" tp:"+DoubleToString(takeprofit));

	if (!IsConnected())
     {
      OrderReliablePrint("error: IsConnected() == false");
      _OR_err = ERR_NO_CONNECTION;
      return(false);
     }

	if (IsStopped())
     {
      OrderReliablePrint("error: IsStopped() == true");
      return(false);
     }

	int cnt = 0;
	while(!IsTradeAllowed() && cnt<retry_attempts)
     {
      OrderReliable_SleepRandomTime(sleep_time, sleep_maximum);
      cnt++;
     }
	if (!IsTradeAllowed())
     {
      if (ErrorLevel>1)
         OrderReliablePrint("error: no operation possible because IsTradeAllowed()==false, even after retries.");
      _OR_err = ERR_TRADE_CONTEXT_BUSY;
      return(false);
     }

	if (false)
     {
      // This section is 'nulled out', because
      // it would have to involve an 'OrderSelect()' to obtain
      // the symbol_ string, and that would change the global context of the
      // existing OrderSelect, and hence would not be a drop-in replacement
      // for OrderModify().
      // 
      // See OrderModifyReliableSymbol() where the user passes in the Symbol
      // manually.

//      OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
      o_position.SelectByTicket(ticket);
      symbol_  = o_position.Symbol();
      int digits = (int)SymbolInfoInteger(symbol_, SYMBOL_DIGITS);
      if (digits>0)
        {
         price       = NormalizeDouble(price, digits);
         stoploss    = NormalizeDouble(stoploss, digits);
         takeprofit  = NormalizeDouble(takeprofit, digits);
        }
      if (stoploss!=0)
         OrderReliable_EnsureValidSL(symbol_, price, stoploss);
      if (takeprofit!=0)
         OrderReliable_EnsureValidTP(symbol_, price, takeprofit);
     }

	int err = GetLastError(); // so we clear the global variable.
	err = 0;
	_OR_err = 0;
	bool exit_loop = false;
	cnt = 0;
	bool result = false;

	while(!exit_loop)
     {
      if (IsTradeAllowed())
        {
        ResetLastError();
         // result = OrderModify(ticket, price, stoploss, takeprofit, expiration, arrow_color);
         o_trade.PositionModify(ticket, stoploss, takeprofit);
         result = true;
         err = GetLastError();
         _OR_err = err;
        }
      else
         cnt++;

      if (result==true)
         exit_loop = true;

      switch(err)
        {
         case ERR_NO_ERROR:
            exit_loop = true;
            break;

         case ERR_NO_RESULT:
            // modification without changing a parameter.
            // if you get this then you may want to change the code.
            exit_loop = true;
            break;

         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_TRADE_CONTEXT_BUSY:
         case ERR_TRADE_TIMEOUT:      // for modify this is a retryable error, I hope.
            cnt++;    // a retryable error
            break;

         case ERR_PRICE_CHANGED:
         case ERR_REQUOTE:
            continue;    // we can apparently retry immediately according to MT docs.

         default:
            // an apparently serious, unretryable error.
            exit_loop = true;
            break;

}  // end switch

if (cnt > retry_attempts)
	exit_loop = true;

if (!exit_loop)
{
	OrderReliable_SleepRandomTime(sleep_time, sleep_maximum);
}

if (exit_loop)
{
	if ((err != ERR_NO_ERROR) && (err != ERR_NO_RESULT))
	{
      // Optionally, you can print the non-retryable error message using the following line:
      // Print("non-retryable error: " + OrderReliableErrTxt(err));
	}

	if (cnt > retry_attempts)
	{
      // Optionally, you can print the retry attempts maxed message using the following line:
      // Print("retry attempts maxed at " + retry_attempts);
	}
}

// we have now exited from loop.
if ((result == true) || (err == ERR_NO_ERROR))
{
	// Optionally, you can print the "Apparently successful modification order" message using the following line:
	// Print("Apparently successful modification order, updated trade details follow.");
	// OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
	o_position.SelectByTicket(ticket);
	OrderPrint();
	return true; // SUCCESS!
}

     }

	if (err==ERR_NO_RESULT)
     {
      OrderReliablePrint("Server reported modify order did not actually change parameters.");
      OrderReliablePrint("redundant modification: "+IntegerToString(ticket)+" "+symbol_+
                         "@"+DoubleToString(price)+" tp@"+DoubleToString(takeprofit)+" sl@"+DoubleToString(stoploss));
      OrderReliablePrint("Suggest modifying code logic to avoid.");
      return(true);
     }

	OrderReliablePrint("failed to execute modify after "+IntegerToString(cnt)+" retries");
	OrderReliablePrint("failed modification: "+IntegerToString(ticket)+" "+symbol_+
                      "@"+DoubleToString(price)+" tp@"+DoubleToString(takeprofit)+" sl@"+DoubleToString(stoploss));
	OrderReliablePrint("last error: "+OrderReliableErrTxt(err));

	return(false);
}
// +------------------------------------------------------------------+
// |                                                                  |
// +------------------------------------------------------------------+
void OrderReliablePrint(string s)
{
// Print to log prepended with stuff;
	if (!(IsTesting() || IsOptimization()))
     {
      if (ErrorLevel>0)
         Print(OrderReliable_Fname+" "+OrderReliableVersion+":"+s);
     }
}
// +------------------------------------------------------------------+
void OrderReliable_SleepRandomTime(double mean_time, double max_time)
{
	if (IsTesting())
      return;    // return immediately if backtesting.

	double tenths = MathCeil(mean_time/0.1);
	if (tenths<=0)
      return;

	int maxtenths = (int)MathRound(max_time/0.1);
	double p = 1.0-1.0/tenths;

	Sleep(100);    // one tenth of a second PREVIOUS VERSIONS WERE STUPID HERE.

	for(int i = 0; i<maxtenths; i++)
     {
      if (MathRand()>p*32768)
         break;

      // MathRand() returns in 0..32767
      Sleep(100);
     }
}

void OrderReliable_EnsureValidSL(string sym, double price, double &sl)
{
// Return if no S/L
	if (sl==0)
      return;

	double servers_min_stop = SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL) * SymbolInfoDouble(sym, SYMBOL_POINT);



	if (MathAbs(price-sl)<=servers_min_stop)
     {
      // we have to adjust the stop.
      if (price>sl)
         sl = price-servers_min_stop;   // we are long

      else
         if (price<sl)
            sl = price+servers_min_stop;   // we are short

         else
            OrderReliablePrint("EnsureValidStop: error, passed in price == sl, cannot adjust");

      sl = NormalizeDouble(sl,(int)SymbolInfoInteger(sym, SYMBOL_DIGITS));


     }
}
// +------------------------------------------------------------------+
// |                                                                  |
// +------------------------------------------------------------------+
void OrderReliable_EnsureValidTP(string symbol1_, double price, double &tp)
{
// Return if no S/L
	if (tp==0)
      return;

	double servers_min_stop = SymbolInfoInteger(symbol1_, SYMBOL_TRADE_STOPS_LEVEL) * SymbolInfoDouble(symbol1_, SYMBOL_POINT);

	if (MathAbs(price-tp)<=servers_min_stop)
     {
      // we have to adjust the stop.
      if (price<tp)
         tp = price+servers_min_stop;   // we are long

      else
         if (price>tp)
            tp = price-servers_min_stop;   // we are short

         else
            OrderReliablePrint("EnsureValidStop: error, passed in price == tp, cannot adjust");

      tp = NormalizeDouble(tp,(int)SymbolInfoInteger(symbol1_, SYMBOL_DIGITS));
     }
}
// +------------------------------------------------------------------+
// |                                                                  |
// +------------------------------------------------------------------+
string OrderReliableErrTxt(int err)
{
	return ("" + IntegerToString(err) + ":" + ErrorDescription(err));
}
// +------------------------------------------------------------------+
double start_equity = 0; // Declare these at global scope
double start_balance_or_equity = 0;
bool isTradingEnabled = true;
double start_balance = AccountBalance();

// +------------------------------------------------------------------+

void CheckEquityProtector()
{
    double current_equity = AccountEquity(); // Add this line to get the current equity

    if (GlobalVariableGet(Symbol() + teststring + "-EP Hit") > 0)
    {
    }
    else
    {
        m_ep_label.Text("Equity Protector: ENABLED");
    }

    double floating_loss = 0;
    double MDL_floating_loss = 0;

    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (!o_position.SelectByIndex(i))
        {
            break;
        }
        if (o_position.Magic() == mn)
        {
            floating_loss += o_position.Profit() + o_position.Commission() + o_position.Swap();
            MDL_floating_loss = floating_loss;
        }
    }

    if (DayCount != TimeDay(TimeCurrent()))
    {
        DayCount = TimeDay(TimeCurrent());

        if (equity_protector_type == ep_MDL_Equity)
        {
            if (TimeHour(TimeCurrent()) == 0 && TimeMinute(TimeCurrent()) == 0)
            {
                start_equity = AccountEquity(); // Check account equity at midnight
            }

            double daily_profit = current_equity - start_equity;
            double max_daily_drawdown = start_balance * 0.05; // Max daily drawdown as 5% of initial deposit

            double max_daily_loss = start_equity - (start_balance * 0.05); // Calculate the maximum daily loss limit

            if (daily_profit > 0)
            {
                max_daily_loss += daily_profit; // Increase the maximum daily loss limit by the daily profit
            }

            if (floating_loss <= -max_daily_loss)
            {
                isTradingEnabled = false; // Disable trading

                // Close all trades
                for (int i = PositionsTotal() - 1; i >= 0; i--)
                {
                    if (!o_position.SelectByIndex(i))
                    {
                        break;
                    }

                    // Close individual positions
                    o_trade.PositionClose(o_position.Ticket());
                }

                Print("EP HIT"); // Display EP HIT message in the Experts tab
            }
        }
        else if (equity_protector_type == ep_MDL_Highest_Value)
        {
            start_balance_or_equity = MathMax(AccountBalance(), AccountEquity()); // Check which is higher, balance or equity
            double daily_floating = start_balance_or_equity + floating_loss;
            if (daily_floating <= equity_protector_value)
            {
                isTradingEnabled = false; // Disable trading

                // Close all trades
                for (int i = PositionsTotal() - 1; i >= 0; i--)
                {
                    if (!o_position.SelectByIndex(i))
                    {
                        break;
                    }

                    // Close individual positions
                    o_trade.PositionClose(o_position.Ticket());
                }

                Print("EP HIT"); // Display EP HIT message in the Experts tab
            }
        }
        else if (equity_protector_type == ep_MDL_Balance)
        {
            start_balance = AccountBalance(); // Check account balance at midnight
            double daily_floating = start_balance + floating_loss;
            if (daily_floating <= equity_protector_value)
            {
                isTradingEnabled = false; // Disable trading

                // Close all trades
                for (int i = PositionsTotal() - 1; i >= 0; i--)
                {
                    if (!o_position.SelectByIndex(i))
                    {
                        break;
                    }

                    // Close individual positions
                    o_trade.PositionClose(o_position.Ticket());
                }

                Print("EP HIT"); // Display EP HIT message in the Experts tab
            }
        }
    }

    if ((equity_protector_type == ep_floating_loss && floating_loss <= (equity_protector_value * -1)) ||
        (equity_protector_type == ep_account_percent && ((floating_loss / AccountBalance()) * 100) <= (equity_protector_value * -1)) ||
        (equity_protector_type == ep_MDL_Balance && MDL_floating_loss <= (equity_protector_value * -1)) ||
        (equity_protector_type == ep_MDL_Equity && MDL_floating_loss <= (equity_protector_value * -1)) ||
        (equity_protector_type == ep_MDL_Highest_Value && MDL_floating_loss <= (equity_protector_value * -1)))
    {
        isTradingEnabled = false; // Disable trading

        // Close all trades
        for (int i = PositionsTotal() - 1; i >= 0; i--)
        {
            if (!o_position.SelectByIndex(i))
            {
                break;
            }

            // Close individual positions
            o_trade.PositionClose(o_position.Ticket());
        }

        Print("EP HIT"); // Display EP HIT message in the Experts tab


if (equity_protector_auto_resume_type == ep_next_day)
{
    datetime currentTime = 0;

    if (TimeBase == TIME_BASE_MARKET_WATCH)
    {
        currentTime = TimeCurrent(); // Market watch time
    }
    else if (TimeBase == TIME_BASE_VPS)
    {
        currentTime = GetVPSTime(); // VPS Time
    }

    int serverDay = TimeDay(currentTime);

    // Check if the current time is the start of the new day (00:00 - 01:59)
    if (TimeHour(currentTime) >= 0 && TimeHour(currentTime) < 2)
    {
        GlobalVariableSet(Symbol() + teststring + "-EP Hit", currentTime);
        // Here you re-enable trading for the next day
        isTradingEnabled = true;

    }
    else
    {

    }
}



if (equity_protector_auto_resume_type == ep_next_week)
{
    datetime currentTime = 0;

    if (TimeBase == TIME_BASE_MARKET_WATCH)
    {
        currentTime = TimeCurrent(); // Market watch time
    }
    else if (TimeBase == TIME_BASE_VPS)
    {
        currentTime = GetVPSTime(); // VPS Time
    }

    int serverDayOfWeek = TimeDayOfWeek(currentTime);


    // Check if it's Monday and the time is within the market opening window (00:00 - 02:00)
    if (serverDayOfWeek == 1 && TimeHour(currentTime) >= 0 && TimeHour(currentTime) < 2)
    {
        GlobalVariableSet(Symbol() + teststring + "-EP Hit", 0);
        // Here you re-enable trading for the next week
        isTradingEnabled = true;

    }
    else
    {

    }
}



        else if (equity_protector_auto_resume_type == ep_immediately)
        {
            // Here you re-enable trading immediately
            isTradingEnabled = true;
        }
        else if (equity_protector_auto_resume_type == ep_false)
        {
            // No resume action, do nothing
        }
        else
        {
            // Handle any other custom resume type here
        }

        for (int i = PositionsTotal() - 1; i >= 0; i--)
        {
            if (!o_position.SelectByIndex(i))
            {
                break;
            }
            if (o_position.Magic() == mn)
            {
                // Perform actions specific to resumed positions
            }
        }

        // Debug print statements for MDL Equity and MDL Highest Value
        if (equity_protector_type == ep_MDL_Equity || equity_protector_type == ep_MDL_Highest_Value)
        {
            if (start_equity > 0 && (start_equity - current_equity >= equity_protector_value))
            {
                Print("MDL Equity or MDL Highest Value condition met!");

            }
        }
    }
}



void ResetEquityProtector()
{
    datetime currentTime = 0;

    if (TimeBase == TIME_BASE_MARKET_WATCH)
    {
        currentTime = TimeCurrent(); // Market watch time
    }
    else if (TimeBase == TIME_BASE_VPS)
    {
        currentTime = GetVPSTime(); // VPS Time
    }

    int serverDayOfWeek = TimeDayOfWeek(currentTime);

    // Check if it's Monday and the time is within the market opening window (00:00 - 02:00)
    if (equity_protector_auto_resume_type == ep_next_week && serverDayOfWeek == 1 && TimeHour(currentTime) >= 0 && TimeHour(currentTime) < 2)
    {
        GlobalVariableDel(Symbol() + teststring + "-EP Hit");
        // Here you re-enable trading for the next week
        isTradingEnabled = true;
        // Reset start equity and start balance/equity values
        if (equity_protector_type == ep_MDL_Equity || equity_protector_type == ep_MDL_Highest_Value)
        {
            start_equity = 0;
            start_balance_or_equity = 0;
        }
        // Print the day and time when EP is resumed
    }

    if (
        (
            (equity_protector_type == ep_MDL_Balance || equity_protector_type == ep_MDL_Equity || equity_protector_type == ep_MDL_Highest_Value) && equity_protector_auto_resume_type == ep_next_day && (TimeHour(currentTime) >= 0 && TimeHour(currentTime) <= 1) && TimeMinute(currentTime) < 5 && currentTime >= (GlobalVariableGet(Symbol() + teststring + "-EP Hit") + TimeDiff) + PERIOD_D1
        ) ||
        (
            (equity_protector_type == ep_account_percent || equity_protector_type == ep_floating_loss) && equity_protector_auto_resume_type == ep_next_day && TimeHour(iTime(Symbol(), PERIOD_D1, 0)) == 0 && TimeMinute(iTime(Symbol(), PERIOD_D1, 0)) < 5 && iTime(Symbol(), PERIOD_D1, 0) >= GlobalVariableGet(Symbol() + teststring + "-EP Hit") + PERIOD_D1
        )
    )
    {
        GlobalVariableDel(Symbol() + teststring + "-EP Hit");
        // Here you re-enable trading when reset
        isTradingEnabled = true;
        // Reset start equity and start balance/equity values
        if (equity_protector_type == ep_MDL_Equity || equity_protector_type == ep_MDL_Highest_Value)
        {
            start_equity = 0;
            start_balance_or_equity = 0;
        }
        // Print the day and time when EP is resumed
    }
}

void CheckSliceON()
{
    double floatingPL = AccountBalance() - AccountEquity();
	if (floatingPL <= -slice_start)
    {
        GlobalVariableSet(teststring+"-Slice ON", 1);
        m_slice_label.Text("Slice Mode: ON");
    }
	if (floatingPL >= -slice_stop)
    {
        GlobalVariableDel(teststring+"-Slice ON");
        m_slice_label.Text("Slice Mode: OFF");
    }
}
// +------------------------------------------------------------------+
void UpdateCut(int buys, int sells)
{
	if (buys>=begin_cut_level)
      GlobalVariableSet(Symbol()+teststring+"-Buy CUT", 1);
	if (sells>=begin_cut_level)
      GlobalVariableSet(Symbol()+teststring+"-Sell CUT", 1);
	if (buys<=0)
      GlobalVariableDel(Symbol()+teststring+"-Buy CUT");
	if (sells<=0)
      GlobalVariableDel(Symbol()+teststring+"-Sell CUT");
}
// +------------------------------------------------------------------+
void Chop()
{

	double dd_perc = ((AccountEquity()-AccountBalance())/AccountBalance())*100;
	int buys = 0, sells = 0;
	if (dd_perc<=chop_threshold_perc*-1)
     {
      for(int i = PositionsTotal()-1; i>=0; i--)
        {
         if (!o_position.SelectByIndex(i)) {break;}
         if (o_position.Magic()==mn && o_position.Symbol()==Symbol())
           {
            if (o_position.PositionType()==POSITION_TYPE_BUY)
               buys++;
            if (o_position.PositionType()==POSITION_TYPE_SELL)
               sells++;
           }
        }
     }
	else
     {
      GlobalVariableDel(Symbol()+teststring+"-Chop SELL");
      GlobalVariableDel(Symbol()+teststring+"-Chop BUY");
     }
	if (buys>=chop_level)
     {
      GlobalVariableSet(Symbol()+teststring+"-Chop BUY", 1);
     }
	else
      GlobalVariableDel(Symbol()+teststring+"-Chop BUY");
	if (sells>=chop_level)
     {
      GlobalVariableSet(Symbol()+teststring+"-Chop SELL", 1);
     }
	else
      GlobalVariableDel(Symbol()+teststring+"-Chop SELL");
}
// +------------------------------------------------------------------+

// +------------------------------------------------------------------+
void ChopBuys()
{
	GlobalVariableSet(Symbol()+teststring+"-Chop BUY reset", TimeCurrent());
	for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if (!o_position.SelectByIndex(i)) {break;}
      if (o_position.Magic()==mn && o_position.Symbol()==Symbol())
        {
         if (o_position.PositionType()==POSITION_TYPE_BUY)
           {
            // if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 10, clrNONE))
            //   Print("OrderClose Error: "+GetLastError());

            o_trade.PositionClose(o_position.Ticket());
           }
        }
     }
}
// +------------------------------------------------------------------+
void ChopSells()
{
	GlobalVariableSet(Symbol()+teststring+"-Chop SELL reset", TimeCurrent());
	for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if (!o_position.SelectByIndex(i)) {break;}
      if (o_position.Magic()==mn && o_position.Symbol()==Symbol())
        {
         if (o_position.PositionType()==POSITION_TYPE_SELL)
           {
            // if (!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 10, clrNONE))
            //   Print("OrderClose Error: "+GetLastError());

            o_trade.PositionClose(o_position.Ticket());
           }
        }
     }
}
// +------------------------------------------------------------------+
void ResetChop()
{
	if (GlobalVariableGet(Symbol()+teststring+"-Chop BUY reset")>0 && TimeCurrent()>=GlobalVariableGet(Symbol()+teststring+"-Chop BUY reset")+resume_chop*60)
    {
        GlobalVariableDel(Symbol()+teststring+"-Chop BUY reset");
        GlobalVariableDel(Symbol()+teststring+"-Chop BUY");
    }
	if (GlobalVariableGet(Symbol()+teststring+"-Chop SELL reset")>0 && TimeCurrent()>=GlobalVariableGet(Symbol()+teststring+"-Chop SELL reset")+resume_chop*60)
    {
        GlobalVariableDel(Symbol()+teststring+"-Chop SELL reset");
        GlobalVariableDel(Symbol()+teststring+"-Chop SELL");
    }
}

bool TradingDayOfWeek(bool bMonday, bool bTuesday, bool bWednesday, bool bThursday, bool bFriday, bool bSaturday, bool bSunday)
{
	int dayOfWeek = DayOfWeek();
	switch(dayOfWeek)
     {
      case 0:
         return bSunday;
      case 1:
         return bMonday;
      case 2:
         return bTuesday;
      case 3:
         return bWednesday;
      case 4:
         return bThursday;
      case 5:
         return bFriday;
      case 6:
         return bSaturday;
      default:
         return false;
     }
}

void CloseAllTradesOnTime(int dayOfWeek, string time)
{
	int currentDayOfWeek = DayOfWeek();
	int currentHour = Hour();
	int currentMinute = Minute();
	int inputHour = 0;
	int inputMinute = 0;
	for(int i = 0; i < StringLen(time); i++)
	{
      if (time[i] == ':')
        {
         inputHour = (int)StringToInteger(StringSubstr(time, 0, i));
         inputMinute = (int)StringToInteger(StringSubstr(time, i + 1, 2));
         break;
        }
	}

	if (currentDayOfWeek > dayOfWeek || (currentDayOfWeek == dayOfWeek && (currentHour > inputHour || (currentHour == inputHour && currentMinute >= inputMinute))))
     {
      GlobalVariableSet("GEN"+teststring+"-CloseForWeek", 1);
      int totalTrades = PositionsTotal();
      for(int i = totalTrades-1; i >= 0; i--)
        {
         if (o_position.SelectByIndex(i) && o_position.Magic()==mn)
           {
            // OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 3, clrNONE);
            o_trade.PositionClose(o_position.Ticket());
           }
        }
     }
	else
      GlobalVariableDel("GEN"+teststring+"-CloseForWeek");
}
// +------------------------------------------------------------------+
void PauseAllTradesOnTime(int dayOfWeek, string time)
{
	int currentDayOfWeek = DayOfWeek();
	int currentHour = Hour();
	int currentMinute = Minute();
	int inputHour = 0;
	int inputMinute = 0;
	for(int i = 0; i < StringLen(time); i++)
     {
      if (time[i] == ':')
        {
         inputHour = (int)StringToInteger(StringSubstr(time, 0, i));
         inputMinute = (int)StringToInteger(StringSubstr(time, i + 1, 2));
         break;
        }
     }
	if (currentDayOfWeek > dayOfWeek || (currentDayOfWeek == dayOfWeek && (currentHour > inputHour || (currentHour == inputHour && currentMinute >= inputMinute))))
     {
      GlobalVariableSet(Symbol()+teststring+"-PAUSE-ACTIVE", 1);
     }
	else
      GlobalVariableDel(Symbol()+teststring+"-PAUSE-ACTIVE");

	int last_ticket = GetLastClosedTradeTicket();
	CheckTakeProfit(last_ticket);
}
// +------------------------------------------------------------------+
int GetLastClosedTradeTicket()
{

	/* CHECK THIS!!!!!!!!!
	int totalHistory = OrdersHistoryTotal();
	for(int i = totalHistory - 1; i >= 0; i--)
     {
      if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) && OrderSymbol()==Symbol() && OrderMagicNumber()==mn)
        {
         if (OrderCloseTime() > 0)
           {
            return OrderTicket();
           }
        }
     }
	*/



	return -1;
}
// +------------------------------------------------------------------+
// |                                                                  |
// +------------------------------------------------------------------+
bool CheckTakeProfit(int ticket)
{
	return false;
	/* CHECK THIS!!!!!!!!
	if (!OrderSelect(ticket, SELECT_BY_TICKET))
     {
      return false;
     }

	double takeProfit = OrderTakeProfit();
	if (takeProfit <= 0.0)
     {
      return false;
     }

	double entryPrice = OrderOpenPrice();
	double closePrice = OrderClosePrice();
	int cmd = OrderType();
	if((cmd == OP_BUY && closePrice >= takeProfit))
     {
      GlobalVariableSet(Symbol()+teststring+"-PAUSE-BUY", 1);
     }
	if((cmd == OP_SELL && closePrice <= takeProfit))
     {
      GlobalVariableSet(Symbol()+teststring+"-PAUSE-SELL", 1);
     }

	return ((cmd == OP_BUY && closePrice >= takeProfit) || (cmd == OP_SELL && closePrice <= takeProfit));

	*/
}
// +------------------------------------------------------------------+
void UpdatePanelLabels()
{
	double Buys[];
	double Sells[];
	bool buy_cut = GlobalVariableGet(Symbol()+teststring+"-Buy CUT")>0;
	bool sell_cut = GlobalVariableGet(Symbol()+teststring+"-Sell CUT")>0;

	ArrayResize(Buys, 0, 0);
	ArrayResize(Sells, 0, 0);


	datetime lastbuytime = 0, lastselltime = 0;
	int lastbuyticket = 0, lastsellticket = 0;
	double highestbuy = 0;
	double highestsell = 0;
	double lowestbuy = 10000000;
	double lowestsell = 10000000;
	int cut_sell = 0, cut_buy = 0;
	double cut_sell_price = 100000;
	double cut_buy_price = 0;
	for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if (!o_position.SelectByIndex(i)) {break;}
         continue;
      if (o_position.Symbol()==Symbol() && o_position.Magic()==mn)
        {
         if (o_position.PositionType()==POSITION_TYPE_BUY)
           {
            if (o_position.PriceOpen()>cut_buy_price)
              {
               cut_buy_price = o_position.PriceOpen();
               cut_buy = (int)o_position.Ticket();
              }
            if (o_position.PriceOpen()>highestbuy)
               highestbuy = o_position.PriceOpen();
            if (o_position.PriceOpen()<lowestbuy)
               lowestbuy = o_position.PriceOpen();
            ArrayResize(Buys, ArraySize(Buys)+1, 0);
            Buys[ArraySize(Buys)-1]=o_position.Volume();
            if (o_position.Time()>lastbuytime)
              {
               lastbuytime = o_position.Time();
               lastbuyticket = (int)o_position.Ticket();
              }
           }
         if (o_position.PositionType()==POSITION_TYPE_SELL)
           {
            if (o_position.PriceOpen()<cut_sell_price)
              {
               cut_sell_price = o_position.PriceOpen();
               cut_sell = (int)o_position.Ticket();
              }
            if (o_position.PriceOpen()>highestsell)
               highestsell = o_position.PriceOpen();
            if (o_position.PriceOpen()<lowestsell)
               lowestsell = o_position.PriceOpen();
            ArrayResize(Sells, ArraySize(Sells)+1, 0);
            Sells[ArraySize(Sells)-1]=o_position.Volume();
            if (o_position.Time()>lastselltime)
              {
               lastselltime = o_position.Time();
               lastsellticket = (int)o_position.Ticket();
              }
           }
        }
     }
	double next_pip_step_buys = GetPipStep();
	if (ArraySize(Buys)>1 && pip_step_multiplier!=1 && GlobalVariableGet(Symbol()+teststring+"-PSM-BUY")<=0)
      next_pip_step_buys*=((ArraySize(Buys)-1)*pip_step_multiplier);
	if (GlobalVariableGet(Symbol()+teststring+"-PSM-BUY")>0)
     {
      int str_lvls = psm_interval;
      if (str_lvls<=0)
         str_lvls = 1;
      int lvls = (int)((ArraySize(Buys)-GlobalVariableGet(Symbol()+teststring+"-PSM-BUY"))/str_lvls);
      for(int v = 1; v<=lvls; v++)
         next_pip_step_buys*=psm_multiplier;
     }
	double next_pip_step_sells = GetPipStep();
	if (ArraySize(Sells)>1 && pip_step_multiplier!=1 && GlobalVariableGet(Symbol()+teststring+"-PSM-SELL")<=0)
      next_pip_step_sells*=((ArraySize(Sells)-1)*pip_step_multiplier);
	if (GlobalVariableGet(Symbol()+teststring+"-PSM-SELL")>0)
     {
      int str_lvls = psm_interval;
      if (str_lvls<=0)
         str_lvls = 1;
      int lvls= (int)((ArraySize(Sells)-GlobalVariableGet(Symbol()+teststring+"-PSM-SELL"))/str_lvls);
      for(int v = 1; v<=lvls; v++)
         next_pip_step_sells*=psm_multiplier;
     }

	m_cpip_label.Text("Current Pip Step (Buys/Sells): "+DoubleToString(next_pip_step_buys/Point(), 0)+" / "+DoubleToString(next_pip_step_sells/Point(), 0));

	m_phanlvls_label.Text("Phantom Levels (Buys/Sells): "+IntegerToString(phantom_buys)+" / "+IntegerToString(phantom_sells));

	m_maxcharts_label.Text("Max Charts: "+IntegerToString(charts_open)+" / "+IntegerToString(max_charts));

	if (use_acc_tp)
     {
      m_account_tp_label.Text("Account TP: $"+DoubleToString(AccountEquity(), 2)+" / $"+DoubleToString(acc_tp, 2));
     }
	else
     {
      m_account_tp_label.Text("Account TP: DISABLED");
     }

	if (use_profit_bucket)
     {
      m_pb_label.Text("Profit Bucket: $"+DoubleToString(profit_bucket, 2)+" / $"+DoubleToString(profit_bucket_goal, 2));
     }
	else
     {
      m_pb_label.Text("Profit Bucket: DISABLED");
     }

	if (use_floating_buckets)
     {
     }
	else
     {
      m_fb_label.Text("Floating Bucket: DISABLED");
     }

	if (!use_weekly_goal)
      m_weekly_label.Text("Weekly Goal: DISABLED");

	if (!use_daily_goal)
      m_daily_goal_label.Text("Daily Goal: DISABLED");

	if (!use_acc_sl)
      m_account_sl_label.Text("Account SL: DISABLED");

	if (!use_equity_protector)
      m_ep_label.Text("Equity Protector: DISABLED");

	if (use_equity_protector)
     {
      if (GlobalVariableGet(Symbol()+teststring+"-EP Hit")>0)
        {

         if (equity_protector_auto_resume_type==0)
           {
            m_ep_label.Text("Equity Protector: EP Hit, resume tomorrow");
           }
         else
           {
            m_ep_label.Text("Equity Protector: EP Hit");
            m_ep_reset_button.Color(clrGreen);
           }
        }
     }

	if (!use_slice_mode)
      m_slice_label.Text("Slice Mode: DISABLED");

	if (!use_lot_multiplier_manager)
     {
      m_lot_mode_buy_label.Text("Lot Mode Manager (Buy): DISABLED");
      m_lot_mode_sell_label.Text("Lot Mode Manager (Sell): DISABLED");
     }
	else
     {
      if (GlobalVariableGet(Symbol()+teststring+"-LMM-BUY")>0)
        {
         m_lot_mode_buy_label.Text("Lot Mode Manager (Buy): ON");
        }
      else
        {
         m_lot_mode_buy_label.Text("Lot Mode Manager (Buy): OFF");
        }
      if (GlobalVariableGet(Symbol()+teststring+"-LMM-SELL")>0)
        {
         m_lot_mode_sell_label.Text("Lot Mode Manager (Sell): ON");
        }
      else
        {
         m_lot_mode_sell_label.Text("Lot Mode Manager (Sell): OFF");
        }
     }

	if (!use_fb_manager)
     {
      m_floating_bm_label.Text("Floating Bucket Manager: DISABLED");
     }
	else
     {
      if (GlobalVariableGet(Symbol()+teststring+"-FBM")>0)
        {
         m_floating_bm_label.Text("Floating Bucket Manager: ON");
        }
      else
        {
         m_floating_bm_label.Text("Floating Bucket Manager: OFF");
        }
     }

	if (GlobalVariableGet(Symbol()+teststring+"-FB Hit")>0)
      m_fb_reset_button.Color(clrGreen);
	if (GlobalVariableGet(Symbol()+teststring+"PB_Goal_Reached")>0)
     {

     }

}

void CheckDailyValues()
{
    datetime today = iTime(Symbol(), PERIOD_D1, 0);
	if (today > GlobalVariableGet("DailyCheck"+teststring))
    {
        GlobalVariableSet("DailyCheck"+teststring, today);
        GlobalVariableSet("DailyStartBalance"+teststring, AccountBalance());
        GlobalVariableSet("DailyStartEquity"+teststring, AccountEquity());
    }
	m_daily_start_label.Text("Daily Start Balance: $"+DoubleToString(GlobalVariableGet("DailyStartBalance"+teststring), 2));
}

void UpdateNews()
{
// --- define the XML Tags, Vars
	string sTags[7]= {"<title>","<country>","<date><![CDATA[","<time><![CDATA[","<impact><![CDATA[","<forecast><![CDATA[","<previous><![CDATA["};
	string eTags[7]= {"</title>","</country>","]]></date>","]]></time>","]]></impact>","]]></forecast>","]]></previous>"};
	int index = 0;
	int next = -1;
	int BoEvent = 0, begin = 0, end = 0;
	string myEvent = "";
// --- Minutes calculation
	datetime EventTime = 0;
	int EventMinute = 0;
// --- split the currencies into the two parts
	string MainSymbol = StringSubstr(Symbol(), 0, 3);
	string SecondSymbol = StringSubstr(Symbol(), 3, 3);
// --- loop to get the data from xml tags
	while(true)
     {
      BoEvent = StringFind(sData,"<event>", BoEvent);
      if (BoEvent==-1)
         break;
      BoEvent += 7;
      next = StringFind(sData,"</event>", BoEvent);
      if (next == -1)
         break;
      myEvent = StringSubstr(sData, BoEvent, next-BoEvent);
      BoEvent = next;
      begin = 0;
      for(int i = 0; i<7; i++)
        {
         Event[index][i]="";
         next = StringFind(myEvent, sTags[i], begin);
         // --- Within this event, if tag not found, then it must be missing; skip it
         if (next==-1)
            continue;
         else
           {
            // --- We must have found the sTag okay...
            // --- Advance past the start tag
            begin = next+StringLen(sTags[i]);
            end = StringFind(myEvent, eTags[i], begin);
            // ---Find start of end tag and Get data between start and end tag
            if (end>begin && end!=-1)
               Event[index][i]=StringSubstr(myEvent, begin, end-begin);
           }
        }
      // --- filters that define whether we want to skip this particular currencies or events
      if (ReportActive && MainSymbol!=Event[index][COUNTRY] && SecondSymbol!=Event[index][COUNTRY])
         continue;
      if (!IsCurrency(Event[index][COUNTRY]))
         continue;
      if (!IncludeHigh && Event[index][IMPACT]=="High")
         continue;
      if (!IncludeMedium && Event[index][IMPACT]=="Medium")
         continue;
      if (!IncludeLow && Event[index][IMPACT]=="Low")
         continue;
      if (!IncludeSpeaks && StringFind(Event[index][TITLE],"Speaks")!=-1)
         continue;
      if (!IncludeHolidays && Event[index][IMPACT]=="Holiday")
         continue;
      if (Event[index][TIME]=="All Day" ||
         Event[index][TIME]=="Tentative" ||
         Event[index][TIME]=="")
         continue;
      if (FindKeyword!="")
        {
         if (StringFind(Event[index][TITLE], FindKeyword)==-1)
            continue;
        }
      if (IgnoreKeyword!="")
        {
         if (StringFind(Event[index][TITLE], IgnoreKeyword)!=-1)
            continue;
        }
      // --- sometimes they forget to remove the tags :)
      if (StringFind(Event[index][TITLE],"<![CDATA[")!=-1)
         StringReplace(Event[index][TITLE],"<![CDATA[","");
      if (StringFind(Event[index][TITLE],"]]>")!=-1)
         StringReplace(Event[index][TITLE],"]]>","");
      if (StringFind(Event[index][TITLE],"]]>")!=-1)
         StringReplace(Event[index][TITLE],"]]>","");
      // ---
      if (StringFind(Event[index][FORECAST],"&lt;")!=-1)
         StringReplace(Event[index][FORECAST],"&lt;","");
      if (StringFind(Event[index][PREVIOUS],"&lt;")!=-1)
         StringReplace(Event[index][PREVIOUS],"&lt;","");

      // --- set some values (dashes) if empty
      if (Event[index][FORECAST]=="")
         Event[index][FORECAST]="---";
      if (Event[index][PREVIOUS]=="")
         Event[index][PREVIOUS]="---";
      // --- Convert Event time to MT4 time
      EventTime = datetime(MakeDateTime(Event[index][DATE], Event[index][TIME]));
      // --- calculate how many minutes before the event (may be negative)
      EventMinute = int(EventTime-TimeGMT())/60+(GMT_Offset*3600);
      // --- only Alert once
      if (EventMinute==0 && AlertTime!=EventTime)
        {
         FirstAlert =false;
         SecondAlert = false;
         AlertTime = EventTime;
        }
      // --- Remove the event after x minutes
      if (EventMinute+EventDisplay<0)
         continue;
      // --- Set buffers
      MinuteBuffer[index]=EventMinute;
      ImpactBuffer[index]=ImpactToNumber(Event[index][IMPACT]);
      index++;
     }
// --- loop to set arrays/buffers that uses to draw objects and alert
	for(int i = 0; i<index; i++)
     {
      for(int n = i; n<10; n++)
        {
         eTitle[n]    = Event[i][TITLE];
         eCountry[n]  = Event[i][COUNTRY];
         eImpact[n]   = Event[i][IMPACT];
         eForecast[n] = Event[i][FORECAST];
         ePrevious[n] = Event[i][PREVIOUS];
         eTime[n]     = datetime(MakeDateTime(Event[i][DATE], Event[i][TIME]))-TimeGMTOffset();
         eMinutes[n]  = (int)MinuteBuffer[i];
         // --- Check if there are any events
         if (ObjectFind(0, eTitle[n])!=0)
            IsEvent = true;
        }
     }
// --- check then call draw / alert function
	if (IsEvent)
      DrawEvents();
	else
      Draw("no more events","NO MORE EVENTS", 14,"Arial Black", RemarksColor, 2, 10, 30,"Get some rest!");
// --- call info function
	if (ShowInfo) {
        SymbolInfo();
	}

	bool news_impact = false;
	for(int i = 0; i<=ArraySize(eImpact)-1; i++)
     {
      // Print(eCountry[i]);
      if (StringFind(Symbol(), eCountry[i], 0)>=0)
        {
         if (eMinutes[i]<=news_action_minutes)
           {
            if (eImpact[i] == "High" && IncludeHigh)
              {
               if (high_action==close_trades)
                  News_Close_Trades = true;
               if (high_action==pause_trades)
                  News_Pause_Trades = true;
              }
            if (eImpact[i] == "Medium" && IncludeMedium)
              {
               if (med_action==close_trades)
                  News_Close_Trades = true;
               if (med_action==pause_trades)
                  News_Pause_Trades = true;
              }
            if (eImpact[i] == "Low" && IncludeLow)
              {
               if (low_action==close_trades)
                  News_Close_Trades = true;
               if (low_action==pause_trades)
                  News_Pause_Trades = true;
              }
           }
        }
     }
	if (!news_impact)
      GlobalVariableDel(Symbol()+teststring+"-News_Impact");

}

void xmlDownload()
{
	ResetLastError();
	string sUrl = "http://nfs.faireconomy.media/ff_calendar_thisweek.xml";
	string res = "";
	StringConcatenate(res, TerminalInfoString(TERMINAL_DATA_PATH),"\\MQL4\\files\\", xmlFileName);
	string FilePath = res;
	int FileGet = URLDownloadToFileW(NULL, sUrl, FilePath, 0, NULL);
}

void xmlRead()
{
	ResetLastError();
	int handle = FileOpen(xmlFileName, FILE_BIN|FILE_READ);
	if (handle == INVALID_HANDLE)
    {
        return;
    }
    // --- receive the file size
    ulong size = FileSize(handle);
    // --- read data from the file
    while(!FileIsEnding(handle)){
        sData = FileReadString(handle,(int)size);
    }
    // --- close
    FileClose(handle);
}

void xmlUpdate()
{
    // --- do not download on saturday
	if (TimeDayOfWeek(Midnight) == 6)
	{
        return;
	}
    FileDelete(xmlFileName);
    xmlDownload();
    xmlRead();
    xmlModifed = (datetime)FileGetInteger(xmlFileName, FILE_MODIFY_DATE, false);
}

void DrawEvents()
{
	string FontName = "Arial";
	string eToolTip = "";
// --- draw backbround / date / special note
	if (ShowPanel && ShowPanelBG)
     {
      eToolTip = "Hover on the Event!";
      Draw("BG","gggg", 85,"Webdings", Pbgc, Corner, x0, 3, eToolTip);
      Draw("Date", DayToStr(Midnight)+", "+MonthToStr()+" "+(string)TimeDay(Midnight), FontSize+1,"Arial Black", TitleColor, Corner, x2_, 95,"Today");
      Draw("Title", PanelTitle, FontSize, FontName, TitleColor, Corner, x1_, 95,"Panel Title");
      Draw("Spreator","------", 10,"Arial", RemarksColor, Corner, x2_, 83, eToolTip);
     }
// --- draw objects / alert functions
	for(int i = 0; i<5; i++)
     {
      eToolTip = eTitle[i]+"\nCurrency: "+eCountry[i]+"\nTime left: "+(string)eMinutes[i]+" Minutes"+"\nImpact: "+eImpact[i];
      // --- impact color
      color EventColor = ImpactToColor(eImpact[i]);
      // --- previous/forecast color
      color ForecastColor = PreviousColor;
      if (ePrevious[i]>eForecast[i])
         ForecastColor = NegativeColor;
      else
         if (ePrevious[i]<eForecast[i])
            ForecastColor = PositiveColor;
      // --- past event color
      if (eMinutes[i]<0)
         EventColor = ForecastColor = PreviousColor = RemarksColor;
      // --- panel
      if (ShowPanel)
        {
         // --- date/time / title / currency
         Draw("Event "+(string)i,
              DayToStr(eTime[i])+"  |  "+
              TimeToString(eTime[i], TIME_MINUTES)+"  |  "+
              eCountry[i]+"  |  "+
              eTitle[i], FontSize, FontName, EventColor, Corner, x2_, 70-i*15, eToolTip);
         // --- forecast
         Draw("Event Forecast "+(string)i,"[ "+eForecast[i]+" ]", FontSize, FontName, ForecastColor, Corner, xf, 70-i*15,
              "Forecast: "+eForecast[i]);
         // --- previous
         Draw("Event Previous "+(string)i,"[ "+ePrevious[i]+" ]", FontSize, FontName, PreviousColor, Corner, xp, 70-i*15,
              "Previous: "+ePrevious[i]);
        }
      // --- vertical news
      if (ShowVerticalNews)
         DrawLine("Event Line "+(string)i, eTime[i]+(ChartTimeOffset*3600), EventColor, eToolTip);
      // --- Set alert message
      string AlertMessage = (string)eMinutes[i]+" Minutes until ["+eTitle[i]+"] Event on "+eCountry[i]+
                          "\nImpact: "+eImpact[i]+
                          "\nForecast: "+eForecast[i]+
                          "\nPrevious: "+ePrevious[i];
      // --- first alert
      if (Alert1Minutes!=-1 && eMinutes[i]==Alert1Minutes && !FirstAlert)
        {
         SetAlerts("First Alert! "+AlertMessage);
         FirstAlert = true;
        }
      // --- second alert
      if (Alert2Minutes!=-1 && eMinutes[i]==Alert2Minutes && !SecondAlert)
        {
         SetAlerts("Second Alert! "+AlertMessage);
         SecondAlert = true;
        }
      // --- break if no more data
      if (eTitle[i]==eTitle[i+1])
        {
         Draw(INAME+" no more events","NO MORE EVENTS", 8,"Arial", RemarksColor, Corner, x2_, 50-i*15,"Get some rest!");
         break;
        }
     }
// ---
}
// +-----------------------------------------------------------------------------------------------+
// | Subroutine: to ID currency even if broker has added a prefix to the symbol_, and is used to    |
// | determine the news to show, based on the users inputal inputs - by authors (Modified)        |
// +-----------------------------------------------------------------------------------------------+
bool IsCurrency(string symbol)
{
	return ReportForUSD && symbol == "USD"
	    || ReportForGBP && symbol == "GBP"
	    || ReportForEUR && symbol == "EUR"
	    || ReportForCAD && symbol == "CAD"
	    || ReportForAUD && symbol == "AUD"
	    || ReportForCHF && symbol == "CHF"
	    || ReportForJPY && symbol == "JPY"
	    || ReportForNZD && symbol == "NZD"
	    || ReportForCNY && symbol == "CNY";
}
// +------------------------------------------------------------------+
// | Converts ff time & date into yyyy.mm.dd hh:mm - by deVries       |
// +------------------------------------------------------------------+
string MakeDateTime(string strDate, string strTime)
{
// ---
	int n1stDash = StringFind(strDate, "-");
	int n2ndDash = StringFind(strDate, "-", n1stDash+1);

	string strMonth = StringSubstr(strDate, 0, 2);
	string strDay = StringSubstr(strDate, 3, 2);
	string strYear = StringSubstr(strDate, 6, 4);

	int nTimeColonPos = StringFind(strTime,":");
	string strHour = StringSubstr(strTime, 0, nTimeColonPos);
	string strMinute = StringSubstr(strTime, nTimeColonPos+1, 2);
	string strAM_PM = StringSubstr(strTime, StringLen(strTime)-2);

	long nHour24 = StringToInteger(strHour);
	if((strAM_PM=="pm" || strAM_PM=="PM") && nHour24!=12)
      nHour24 += 12;
	if((strAM_PM=="am" || strAM_PM=="AM") && nHour24==12)
      nHour24 = 0;
	string strHourPad = "";
	if (nHour24<10)
      strHourPad = "0";

	string res = "";
	StringConcatenate(res, strYear, ".", strMonth, ".", strDay, " ", strHourPad, IntegerToString(nHour24), ":", strMinute);
	return(res);
// ---
}
// +------------------------------------------------------------------+
// | set impact Color - by authors                                    |
// +------------------------------------------------------------------+
color ImpactToColor(string impact)
{
// ---
	if (impact == "High")
      return (HighImpactColor);
	else
      if (impact == "Medium")
         return (MediumImpactColor);
      else
         if (impact == "Low")
            return (LowImpactColor);
         else
            if (impact == "Holiday")
               return (HolidayColor);
            else
               return (RemarksColor);
// ---
}
// +------------------------------------------------------------------+
// | Impact to number - by authors                                    |
// +------------------------------------------------------------------+
int ImpactToNumber(string impact)
{
// ---
	if (impact == "High")
      return(3);
	else
      if (impact == "Medium")
         return(2);
      else
         if (impact == "Low")
            return(1);
         else
            return(0);
// ---
}
// +------------------------------------------------------------------+
// | Convert day of the week to text                                  |
// +------------------------------------------------------------------+
string DayToStr(datetime time)
{
	int ThisDay = TimeDayOfWeek(time);
	string day = "";
	switch(ThisDay)
     {
      case 0:
         day = "Sun";
         break;
      case 1:
         day = "Mon";
         break;
      case 2:
         day = "Tue";
         break;
      case 3:
         day = "Wed";
         break;
      case 4:
         day = "Thu";
         break;
      case 5:
         day = "Fri";
         break;
      case 6:
         day = "Sat";
         break;
     }
	return(day);
}
// +------------------------------------------------------------------+
// | Convert months to text                                           |
// +------------------------------------------------------------------+
string MonthToStr()
{
	MqlDateTime tm;
	TimeCurrent(tm);
	int ThisMonth = tm.mon;
	string month = "";
	switch(ThisMonth)
     {
      case 1:
         month = "Jan";
         break;
      case 2:
         month = "Feb";
         break;
      case 3:
         month = "Mar";
         break;

      case 4:
         month = "Apr";
         break;
      case 5:
         month = "May";
         break;
      case 6:
         month = "Jun";
         break;
      case 7:
         month = "Jul";
         break;
      case 8:
         month = "Aug";
         break;
      case 9:
         month = "Sep";
         break;
      case 10:
         month = "Oct";
         break;
      case 11:
         month = "Nov";
         break;
      case 12:
         month = "Dec";
         break;
     }
	return(month);
}
// +------------------------------------------------------------------+
// | Candle Time Left / Spread                                        |
// +------------------------------------------------------------------+
void SymbolInfo()
{
// ---
	string TimeLeft = TimeToString(iTime(Symbol(), PERIOD_CURRENT, 0)+Period()*60-TimeCurrent(), TIME_MINUTES|TIME_SECONDS);
	string Spread = DoubleToString(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD)/Point(), 1);


	double DayClose = iClose(NULL, PERIOD_D1, 1);
	if (DayClose!=0)
     {
     double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      double Strength = ((Bid-DayClose)/DayClose)*100;
      string Label = DoubleToString(Strength, 2)+"%"+" / "+Spread+" / "+TimeLeft;
      ENUM_BASE_CORNER corner = 1;
      if (Corner==1)
         corner = 3;
      string arrow = "q";
      if (Strength>0)
         arrow = "p";
      string tooltip = "Strength / Spread / Candle Time";
      Draw(INAME+": info", Label, InfoFontSize,"Calibri", InfoColor, corner, 120, 20, tooltip);
      Draw(INAME+": info arrow", arrow, InfoFontSize-2,"Wingdings 3", InfoColor, corner, 130, 18, tooltip);
     }
// ---
}
// +------------------------------------------------------------------+
// | draw event text                                                  |
// +------------------------------------------------------------------+
void Draw(string name, string label, int size, string font, color clr, ENUM_BASE_CORNER c, int x, int y, string tooltip)
{
// ---
	name = INAME+": "+name;
	int windows = 0;
	if (AllowSubwindow && ChartGetInteger(0, CHART_WINDOWS_TOTAL)>1)
      windows = 1;
	ObjectDelete(0, name);
	ObjectCreate(0, name, OBJ_LABEL, windows, 0, 0);
	ObjectSetText(name, label, size, font, clr);
	ObjectSet(name, OBJPROP_CORNER, c);
	ObjectSet(name, OBJPROP_XDISTANCE, x);
	ObjectSet(name, OBJPROP_YDISTANCE, y);
// --- justify text
	ObjectSet(name, OBJPROP_ANCHOR, anchor_);
	ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
	ObjectSet(name, OBJPROP_SELECTABLE, 0);
// ---
}
// +------------------------------------------------------------------+
// | draw vertical lines                                              |
// +------------------------------------------------------------------+
void DrawLine(string name, datetime time, color clr, string tooltip)
{
	name = INAME+": "+name;
	ObjectDelete(0, name);
	ObjectCreate(0, name, OBJ_VLINE, 0, time, 0);
	ObjectSet(name, OBJPROP_COLOR, clr);
	ObjectSet(name, OBJPROP_STYLE, 2);
	ObjectSet(name, OBJPROP_WIDTH, 0);
	ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
}

void SetAlerts(string message)
{
	if (PopupAlerts) {
        Alert(message);
	}
	if (SoundAlerts) {
        PlaySound(AlertSoundFile);
	}
	if (NotificationAlerts) {
        SendNotification(message);
	}
}

void NewsCloseTrades()
{
	for(int v = PositionsTotal()-1; v>=0; v--)
    {
        if (!o_position.SelectByIndex(v)) {
            break;
        }
        if (o_position.Magic() == mn && o_position.Symbol() == Symbol())
        {
            o_trade.PositionClose(o_position.Ticket());
        }
    }
	Alert("All trades closed due to news event!");
}

void CheckUpdateNews()
{
	if (TimeCurrent() < next_news_update) {
	    return;
	}
	next_news_update = TimeCurrent() + (UpdateHour * 3600);
	if (xmlModifed < TimeLocal() - (UpdateHour * 3600))
    {
        xmlUpdate();
    }
}
