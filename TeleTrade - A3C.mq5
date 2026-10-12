//+------------------------------------------------------------------+
//|                                                  TeleTrade - A3C |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

#define CMT_IMAGE_INFO  "/screenshot"
#define CMT_INFO        "/info"
#define CMT_INFO2       "/info2"
#define CMT_CLEAR_ALL   "/clear"
#define CMT_HELP        "/help"
#define CMT_DELETE      "/delete"
#define CMT_BE          "/be"
#define CMT_CLOSE_POS   "/close"
// Khai báo danh sách lệnh động tùy ý ở bên ngoài
string cmds[]  = {CMT_IMAGE_INFO, CMT_INFO, CMT_INFO2, CMT_CLEAR_ALL, CMT_HELP, CMT_DELETE, CMT_BE, CMT_CLOSE_POS};
string descs[] = {
    "Chụp màn hình thông tin",
    "Thông tin lệnh chờ (Tableview)",
    "Thông tin lệnh chờ (Tree View)",
    "Hủy tất cả các lệnh chờ (Pending)",
    "Xem hướng dẫn sử dụng",
    "Xóa lệnh chờ theo thứ tự",
    "Đặt BE cho chuỗi lệnh 1 chiều hiện có",
    "Đóng toàn bộ lệnh hiện có"
};

//+------------------------------------------------------------------+
// Hàm tạo chuỗi trợ giúp động với các mốc giá mẫu khác nhau
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Hàm tạo chuỗi trợ giúp động với các mốc giá mẫu khác nhau        |
//+------------------------------------------------------------------+
string GetDynamicHelpInfo() {
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

// Nếu không lấy được giá Bid (ngoài giờ / lỗi), gán giá mặc định
    if(bid <= 0) bid = 2400.0;

// Bỏ phần thập phân làm gốc tính toán (Ví dụ: 4435.78 -> 4435.0)
    double base_price = MathFloor(bid);

// Ví dụ 1: BUY Đầy đủ (Entry -10, SL -15, TP +20)
    double buy1_entry = NormalizeDouble(base_price - 10.0, _Digits);
    double buy1_sl    = NormalizeDouble(buy1_entry - 15.0, _Digits);
    double buy1_tp    = NormalizeDouble(buy1_entry + 20.0, _Digits);

// Ví dụ 2: SELL Cơ bản (Entry +15, SL +25)
    double sell2_entry = NormalizeDouble(base_price + 15.0, _Digits);
    double sell2_sl    = NormalizeDouble(sell2_entry + 25.0, _Digits);

// Ví dụ 3: BUY Ngắn (Entry -5, SL -10, TP +15)
    double buy3_entry = NormalizeDouble(base_price - 5.0, _Digits);
    double buy3_sl    = NormalizeDouble(buy3_entry - 10.0, _Digits);
    double buy3_tp    = NormalizeDouble(buy3_entry + 15.0, _Digits);

// Ví dụ 4: SELL Dài (Entry +30, SL +20, TP -40)
    double sell4_entry = NormalizeDouble(base_price + 30.0, _Digits);
    double sell4_sl    = NormalizeDouble(sell4_entry + 20.0, _Digits);
    double sell4_tp    = NormalizeDouble(sell4_entry - 40.0, _Digits);

// Xác định thông số Risk hiện tại đang kích hoạt
    string current_risk_info = isRiskUSD
                               ? StringFormat("%.2f$ (USD)", inp_risk)
                               : StringFormat("%.2f%% (Phần trăm)", inp_risk_percent);

    string res = "<b>CÚ PHÁP ĐẶT LỆNH CHỜ</b>\n\n";
    res += "• <b>Bắt buộc:</b> <code>TYPE</code> | <code>ENTRY</code> | <code>SL</code>\n";
    res += "• <b>Tùy chọn:</b> <code>TP</code> | <code>OFFSET</code> | <code>RISKU</code> | <code>RISKP</code>\n";
    res += StringFormat("• <i>Offset tính theo Point, mặc định = %I64u</i>\n", inp_offset);
    res += StringFormat("• <i>Risk hiện tại: %s</i>\n", current_risk_info);
    res += "<i>(Lưu ý: Nhập Risk số dương hay âm bot cũng tự quy về số dương)</i>\n\n";
    res += StringFormat("<i>(Giá Bid hiện tại %s: %.*f)</i>\n\n", _Symbol, _Digits, bid);
    res += "<b>CÁC VÍ DỤ MẪU:</b>\n\n";

// Ví dụ 1: Đầy đủ tham số dùng RISKU ($)
    res += StringFormat("1. Dùng Risk tiền USD (RISKU):\n<code>BUY %.*f SL %.*f TP %.*f OFFSET 50 RISKU 100</code>\n\n",
                        _Digits, buy1_entry, _Digits, buy1_sl, _Digits, buy1_tp);

// Ví dụ 2: Dùng Risk phần trăm (RISKP)
    res += StringFormat("2. Dùng Risk phần trăm %% (RISKP):\n<code>BUY %.*f SL %.*f TP %.*f RISKP 2.5</code>\n\n",
                        _Digits, buy3_entry, _Digits, buy3_sl, _Digits, buy3_tp);

// Ví dụ 3: Chuẩn cơ bản (không TP/Offset/Risk)
    res += StringFormat("3. Chuẩn cơ bản (không TP/Offset/Risk):\n<code>SELL %.*f SL %.*f</code>\n\n",
                        _Digits, sell2_entry, _Digits, sell2_sl);

// Ví dụ 4: Định dạng viết thường (Sell)
    res += StringFormat("4. Viết thường, linh hoạt dấu phân cách:\n<code>sell: %.*f, sl: %.*f, tp: %.*f, offset: 79, risku: 150</code>",
                        _Digits, sell4_entry, _Digits, sell4_sl, _Digits, sell4_tp);

    return res;
}


#include "TelegramLite.mqh"

CCustomBotLite            bot;
#include "MngTrade.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CComm g_com_account("tvl_accint", true);
CComm g_com_pendingorder("tvl_pendingorder", true);


input long MagicNumber = 2026; // Magic Number
input string CmtEA = "Trùm FX"; // Comment Order

input long inp_min_sl_points = 100 ; // SL Tối thiểu tính theo Point
input long inp_be_offset = 100;     // Lợi nhuận khi BE (Point)


input group "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬"
input string inp_tele_api = "api.telegram.org"; // Telegram API

input string inp_tele_token = "xxxxx-yyyyyyyy"; // Telegram Bot TOKEN
input long inp_tele_chat_id = -10000000001;     // Chat ID
input group "▬▬▬▬[ BỘ LỌC TIN NHẮN ]▬▬▬▬"
input long inp_tele_from_id = 10001;            // From ID
input string inp_tele_from_user = "@user";      // From User


//input string inp_tele_token = "8868804342:AAEUJPlqN4asjj_52yE3vESvlexz5ocu8JA"; // Telegram Bot TOKEN
//input long inp_tele_chat_id = -5339016885;      // Chat ID
//input long inp_tele_from_id = 1214;             // From ID
//input string inp_tele_from_user = "@vluc028";    // From User
input group "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬"
//+------------------------------------------------------------------+


bool isSetRisk = false, isSetOffset = false;
long inp_offset = 100; // Trailing Offset
double inp_risk = 100.0;  // Risk USD
double inp_risk_percent = 5.0; // Risk %
bool isRiskUSD = false;
//+------------------------------------------------------------------+
int OnInit() {
//---
    LoadPendingOrders();
    OnTick();

    bot.Init(inp_tele_token, inp_tele_chat_id);

    obj_trade.SetExpertMagicNumber(MagicNumber);

// Gọi hàm truyền mảng vào
    bot.SetMyCommands(cmds, descs);

//---
    ChartSetInteger(0, CHART_SHOW_PRICE_SCALE, false);
    ChartSetInteger(0, CHART_SHOW_DATE_SCALE, false);
    ChartRedraw();
    string shotname = "ChartScreenShot.png";
    if(ChartScreenShot(ChartID(), shotname, 1200, 700, ALIGN_LEFT))
        bot.SendPhoto(shotname, "Cài đặt thành công");
    ChartSetInteger(0, CHART_SHOW_PRICE_SCALE, true);
    ChartSetInteger(0, CHART_SHOW_DATE_SCALE, true);
    ChartRedraw();

    EventSetMillisecondTimer(567);
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    EventKillTimer();
    Comment("");
    SavePendingOrders();
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
uint highaccount = 0;
void OnTick() {

    TrailingEntry();

    string info = GetAllOrdersTable();
    g_com_account.Comm(info, CORNER_LEFT_LOWER, 8, 8, 255, 16);
    uint pre_highaccount = g_com_account.GetHeight();
    if(highaccount != pre_highaccount) {
        highaccount = pre_highaccount;
        g_com_pendingorder.Destroy();
        g_com_pendingorder.Comm(GetAccInfoTable(), CORNER_LEFT_LOWER, 8, 16 + highaccount, 255, 16);
    }

}
//+------------------------------------------------------------------+
void OnChartEvent(const int32_t id, const long& lparam, const double& dparam, const string& sparam) {
    if(id == CHARTEVENT_KEYDOWN && sparam == "25") {
        //ArrayFree(g_pendingorder);

        string shotname = "ChartScreenShot.png";
        if(ChartScreenShot(ChartID(), shotname, MathMax(g_com_account.GetWidth(), g_com_pendingorder.GetWidth()) + 128,
                           g_com_account.GetHeight() + g_com_pendingorder.GetHeight() + 64, ALIGN_LEFT))
            bot.SendPhoto(shotname, "Show Info");
    }
}
//---
string admin_ea = "@LTCong";
//+------------------------------------------------------------------+
string GetRandomRejectMessage(const string sender_name) {
    string templates[] = {
        "🚫 Rất tiếc %s, đây là hệ thống nội bộ!\n👉 Vui lòng liên hệ admin %s để biết thêm chi tiết.",
        "⚠️ Rất tiếc %s, đây là dự án cá nhân!\n👉 Bạn cần cấp quyền từ %s để sử dụng.",
        "⛔️ Xin chào %s, bot hiện không phục vụ tài khoản của bạn.\n👉 Liên hệ %s để được hỗ trợ.",
        "❌ Bạn %s chưa có quyền truy cập bot này!\n👉 Vui lòng nhắn tin cho %s để đăng ký.",
        "🔒 Hệ thống giới hạn người dùng! %s không nằm trong danh sách cấp phép.\n👉 Liên hệ: %s",
        "🤖 Bot cá nhân không hỗ trợ cộng đồng!\n👉 Bạn %s vui lòng liên hệ %s để mở khóa.",
        "🚫 Lệnh bị từ chối! %s chưa được cấp quyền sử dụng.\n👉 Hỗ trợ kỹ thuật: %s",
        "🛡️ Quyền truy cập bị từ chối đối với %s!\n👉 Vui lòng gửi ID cho %s để duyệt tài khoản.",
        "⌛️ %s ơi, bạn chưa có trong danh sách AllowList!\n👉 Nhắn tin ngay cho %s để được kích hoạt.",
        "🔴 Tài khoản %s chưa được xác minh trên hệ thống.\n👉 Vui lòng liên hệ %s để hỗ trợ cài đặt."
    };

    int total = ArraySize(templates);

// Đảm bảo tạo hạt giống ngẫu nhiên theo thời gian thực
    MathSrand((uint)GetTickCount());
    int rand_index = MathRand() % total;

    return StringFormat(templates[rand_index], sender_name, admin_ea);
}
#include <Arrays\ArrayULong.mqh>
CArrayULong g_array_close;
void CheckCloseAll() {
    int total = g_array_close.Total();
    if(total == 0) return;

    obj_trade.SetAsyncMode(true);
    bool is_Done = true;
    for(int i = total - 1; i >= 0; i--) {
        ulong ptk = g_array_close.At(i);
        if(obj_position.SelectByTicket(ptk)) {
            is_Done = false;
            obj_trade.PositionClose(ptk);
        }
    }

    obj_trade.SetAsyncMode(false);

    if(is_Done) g_array_close.Clear();
}
//+------------------------------------------------------------------+
void OnTimer(void) {

    CheckCloseAll();

    STelegramMessage messages[];
    bot.GetUpdate(messages);

    for(int i = 0; i < ArraySize(messages); i++) {
        messages[i].PrintMsg();

// 1. Kiểm tra quyền truy cập (Đúng Chat ID VÀ đúng From ID hoặc From Username)
        bool is_valid_chat = (messages[i].chat_id == inp_tele_chat_id);
        bool is_valid_user = (messages[i].from_id == inp_tele_from_id) ||
                             (messages[i].from_username == inp_tele_from_user && inp_tele_from_user != "");

        if(!is_valid_chat || !is_valid_user) {
            // Lấy tên người dùng để hiển thị trong câu reply
            string sender_name = (messages[i].from_username != "")
                                 ? "@" + messages[i].from_username
                                 : messages[i].from_first_name;

            string err_mess = GetRandomRejectMessage(sender_name); //StringFormat("Không phục vụ quý khách (%s). Vui lòng liên hệ @vluc028", sender_name);

            bot.ReplyMessID(messages[i].chat_id, messages[i].message_id, err_mess, true);
            continue;
        }
//---
        if(HandleSetRiskOffSet(messages[i])) continue; // Set risk/offset thì không xử lý đoạn sau

        if(isSetOffset && isSetRisk) { // Đã set risk và offset mới chạy đoạn này
            if(g_isWaitingForDelete)
                HandleDeleteConfirmation(messages[i]);
            else
                ProcessMessage(messages[i]);
        } //---

        else {
            long chatId = messages[i].chat_id;
            long msgId = messages[i].message_id;

            string set_help = "<b>Lỗi: Chưa Set Mặc định cho Offset hoặc Risk!</b>\n\n" +
                              "Vui lòng thiết lập bằng cú pháp:\n" +
                              "• <code>OFFSET [giá_trị]</code> (Ví dụ: <code>OFFSET 50</code>)\n" +
                              "• <code>RISKU [số_tiền]</code> (Ví dụ: <code>RISKU 100</code>)\n" +
                              "• <code>RISKP [phần_trăm]</code> (Ví dụ: <code>RISKP 1.5</code>)";

            bot.ReplyMessID(chatId, msgId, set_help, true);
        }
    }
}
//+------------------------------------------------------------------+
bool HandleSetRiskOffSet(const STelegramMessage &msg) {
    long chatId = msg.chat_id;
    long msgId = msg.message_id;
// 1. Chuẩn hóa chuỗi
    string text = msg.message_text;



    StringToUpper(text);
    StringReplace(text, ",", " ");
    StringReplace(text, "=", " ");
    StringReplace(text, ":", " ");
    StringReplace(text, ";", " ");
    while(StringFind(text, "  ") >= 0) {
        StringReplace(text, "  ", " ");
    }
    StringTrimLeft(text);
    StringTrimRight(text);
    if(StringFind(text, "BUY") >= 0 || StringFind(text, "SELL") >= 0) return false;
// 2. Tách tokens
    string tokens[];
    int total_tokens = StringSplit(text, ' ', tokens);
    if(total_tokens < 2) {
        //bot.ReplyMessID(chatId, msgId, "Để", true);
        return false;
    }

    string add_text = "";
// 3. Xử lý bóc tách theo từ khóa
    for(int i = 0; i < total_tokens; i++) {
        string token = tokens[i];
        StringTrimLeft(token);
        StringTrimRight(token);
        if(token == "") continue;

        if(token == "RISKU") {
            if(i + 1 < total_tokens) {
                inp_risk = StringToDouble(tokens[i + 1]);
                isRiskUSD = true;
                isSetRisk = true;
                bot.ReplyMessID(chatId, msgId, " Set Risk USD = " + DoubleToString(inp_risk, 2), true);
                i++;
                return true;
            }
        } //---
        else if(token == "RISKP") {
            if(i + 1 < total_tokens) {
                double percent = StringToDouble(tokens[i + 1]);
                if(percent <= 0.0 || percent >= 100.0) {
                    bot.ReplyMessID(chatId, msgId, " Lỗi Set Risk Percent: < 0% hoặc > 100%", false);
                    return true;
                }
                inp_risk_percent = percent;

                isRiskUSD = false;
                isSetRisk = true;
                bot.ReplyMessID(chatId, msgId, " Set Risk Percent = % " + DoubleToString(inp_risk_percent, 2), true);
                i++;
                return true;
            }
        } //---
        else if(token == "OFFSET") {
            if(i + 1 < total_tokens) {
                inp_offset = StringToInteger(tokens[i + 1]);
                i++;
                isSetOffset = true;
                bot.ReplyMessID(chatId, msgId, " Set Offset = " + IntegerToString(inp_offset) + " (Point)", true);
                return true;
            }
        }
    }

    return false;
}
//+------------------------------------------------------------------+
void ProcessMessage(const STelegramMessage &msg) {
    long chatId = msg.chat_id;
    long msgId  = msg.message_id;

// 1. Kiểm tra các lệnh hệ thống
    if(ProcessSystemCommand(msg.message_text, chatId, msgId))
        return;

// 2. Parse lệnh đặt (hàm tự động reply thành công hoặc báo lỗi)
    ParseOrderMessage(msg.message_text, chatId, msgId);
}
//+------------------------------------------------------------------+
bool g_isWaitingForDelete = false;
/*
#define CMT_IMAGE_INFO  "/screenshot"
#define CMT_INFO        "/info"
#define CMT_INFO2       "/info2"
#define CMT_CLEAR_ALL   "/clear"
#define CMT_HELP        "/help"
#define CMT_DELETE      "/delete"
#define CMT_BE          "/be"
#define CMT_CLOSE_POS   "/close"
*/
bool ProcessSystemCommand(const string text, long chatId, long msgId) {
    if(StringFind(text, CMT_DELETE, 0) == 0) {
        HandleDelete(chatId, msgId);
        return true;
    }
    if(StringFind(text, CMT_IMAGE_INFO, 0) == 0) {
        HandleImageInfo();
        return true;
    }
    if(StringFind(text, CMT_INFO2, 0)       == 0) {
        HandleInfo2(chatId, msgId);
        return true;
    }
    if(StringFind(text, CMT_INFO, 0)       == 0) {
        HandleInfo(chatId, msgId);
        return true;
    }
    if(StringFind(text, CMT_CLEAR_ALL, 0)  == 0) {
        HandleClearAll(chatId, msgId);
        return true;
    }
    if(StringFind(text, CMT_HELP, 0)       == 0) {
        HandleHelp(chatId, msgId);
        return true;
    }
//---
    if(StringFind(text, CMT_BE, 0)        == 0) {
        HandleBE(chatId, msgId);
        return true;
    }
    if(StringFind(text, CMT_CLOSE_POS, 0) == 0) {
        HandleCloseAll(chatId, msgId);
        return true;
    }
//---
    return false;
}
//+------------------------------------------------------------------+
void SetChart(bool falg) {
    ChartSetInteger(0, CHART_SHOW_PRICE_SCALE, falg);
    ChartSetInteger(0, CHART_SHOW_DATE_SCALE, falg);
    ChartRedraw();
}
//+------------------------------------------------------------------+
void HandleImageInfo(const string shotname = "ChartScreenShot.png") {
    SetChart(false);

    uint width  = MathMax(g_com_account.GetWidth(), g_com_pendingorder.GetWidth()) + 24;
    uint height = g_com_account.GetHeight() + g_com_pendingorder.GetHeight() + 48;

    if(ChartScreenShot(ChartID(), shotname, width, height, ALIGN_LEFT)) {
        bot.SendPhoto(shotname, "Show Info");
    }
    SetChart(true);
}
//+------------------------------------------------------------------+
void HandleInfo2(long chatId, long msgId) {
    string messs = GetAllOrdersTableTele2();
    bot.ReplyMessID(chatId, msgId, messs, true);
}
//+------------------------------------------------------------------+
void HandleInfo(long chatId, long msgId) {
    string messs = GetAllOrdersTableTele();
    bot.ReplyMessID(chatId, msgId, messs, true);
}
//+------------------------------------------------------------------+
void HandleClearAll(long chatId, long msgId) {
    ArrayFree(g_pendingorder);
    bot.ReplyMessID(chatId, msgId, "Đã xóa toàn bộ mảng lệnh chờ", true);
}
//+------------------------------------------------------------------+
void HandleHelp(long chatId, long msgId) {
    string helpMessage = GetDynamicHelpInfo();
    bot.ReplyMessID(chatId, msgId, helpMessage, true);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void HandleDelete(long chatId, long msgId) {
    int total = ArraySize(g_pendingorder);
    if(total == 0) {
        bot.ReplyMessID(chatId, msgId, "Hiện tại không có lệnh Pending nào để xóa!", true);
        g_isWaitingForDelete = false; // Reset trạng thái
        return;
    }

    string mess = GetDeleteOrderListTele();
    mess += "\n👉 <i>Gửi <b>STT</b> lệnh cần xóa (Ví dụ: <code>1</code> hoặc <code>2</code>)</i>\n";
    mess += "🚫 <i>Gửi <b>ký tự bất kỳ</b> (chữ/lệnh khác) để <b>HỦY</b> thao tác</i>";

// Bật Cache trạng thái chờ xóa
    g_isWaitingForDelete = true;

    bot.ReplyMessID(chatId, msgId, mess, true);
}
//+------------------------------------------------------------------+
void HandleDeleteConfirmation(const STelegramMessage &msg) {
    long chatId = msg.chat_id;
    long msgId  = msg.message_id;

// Ép kiểu trực tiếp về int (nếu chuỗi là chữ/ký tự đặc biệt sẽ trả về 0)
    int stt   = (int)StringToInteger(msg.message_text);
    int total = ArraySize(g_pendingorder);

// Kiểm tra phạm vi STT (1-based)
    if(stt >= 1 && stt <= total) {
        int idx = stt - 1; // Chuyển về Index mảng (0-based)

        string typeStr     = (g_pendingorder[idx].OrderType == ORDER_TYPE_BUY) ? "BUY" : "SELL";
        string deletedInfo = StringFormat("%s @ %.*f", typeStr, _Digits, g_pendingorder[idx].Price);

        ArrayRemove(g_pendingorder, idx, 1);

        string replyMess = StringFormat("✅ Đã xóa thành công lệnh STT <b>[%d]</b> (%s)", stt, deletedInfo);
        bot.ReplyMessID(chatId, msgId, replyMess, true);
    } else {
        // Nhập chữ, nhập 0 hoặc nhập STT vượt quá số lượng lệnh
        string replyMess = StringFormat("❌ STT <b>%s</b> không hợp lệ! Hủy thao tác xóa.", msg.message_text);
        bot.ReplyMessID(chatId, msgId, replyMess, true);
    }

// Luôn reset trạng thái
    g_isWaitingForDelete = false;
}
//+------------------------------------------------------------------+
void HandleCloseAll(long chatId, long msgId) {
    obj_trade.SetAsyncMode(true);
    int count = 0;
    string tickets_str = "";

    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(obj_position.SelectByIndex(i)) {
            ulong ptk = obj_position.Ticket();
            string symbol = obj_position.Symbol();
            double volume = obj_position.Volume();
            ENUM_POSITION_TYPE type = obj_position.PositionType();
            string type_str = (type == POSITION_TYPE_BUY) ? "🔵 BUY" : "🔴 SELL";
            g_array_close.Add(ptk);
            obj_trade.PositionClose(ptk);
            tickets_str += StringFormat("• %s %.2f %s (<code>#%I64u</code>)\n",
                                        type_str, volume, symbol, ptk);
            count++;
        }
    }

    obj_trade.SetAsyncMode(false);

    string replyMess;
    if(count > 0) {
        replyMess = StringFormat("<b>Close All Positions (%d)</b>\n" +
                                 "———————————————\n" +
                                 "🚀 Đã phát lệnh đóng các vị thế:\n%s",
                                 count, tickets_str);
    } else {
        replyMess = "⚠️ Không có vị thế nào đang mở để đóng!";
    }

    bot.ReplyMessID(chatId, msgId, replyMess, true);
}
//+------------------------------------------------------------------+
void HandleBE(long chatId, long msgId) {
    ulong buy_tickets[];
    ulong sell_tickets[];

    double buy_total_vol = 0, sell_total_vol = 0;
    double buy_weighted_sum = 0, sell_weighted_sum = 0;

    int stops_level = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double min_stop_dist = stops_level * _Point;

// 1. Phân loại & Tính toán - CHỈ LỌC CHO _SYMBOL HIỆN TẠI
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(obj_position.SelectByIndex(i)) {
            // Lọc đúng Symbol đang chạy chart
            if(obj_position.Symbol() != _Symbol) continue;

            ulong ptk = obj_position.Ticket();
            ENUM_POSITION_TYPE pos_type = obj_position.PositionType();
            double vol = obj_position.Volume();
            double open_price = obj_position.PriceOpen();

            if(pos_type == POSITION_TYPE_BUY) {
                int size = ArraySize(buy_tickets);
                ArrayResize(buy_tickets, size + 1);
                buy_tickets[size] = ptk;

                buy_total_vol += vol;
                buy_weighted_sum += open_price * vol;
            } else if(pos_type == POSITION_TYPE_SELL) {
                int size = ArraySize(sell_tickets);
                ArrayResize(sell_tickets, size + 1);
                sell_tickets[size] = ptk;

                sell_total_vol += vol;
                sell_weighted_sum += open_price * vol;
            }
        }
    }

    int total_buy_count = ArraySize(buy_tickets);
    int total_sell_count = ArraySize(sell_tickets);

    if(total_buy_count == 0 && total_sell_count == 0) {
        bot.ReplyMessID(chatId, msgId, StringFormat("⚠️ Không có vị thế <b>%s</b> nào đang mở!", _Symbol), true);
        return;
    }

    obj_trade.SetAsyncMode(true);
    string detail_str = "";

// 2. Xử lý BE cho vị thế BUY
    if(total_buy_count > 0 && buy_total_vol > 0) {
        double avg_buy = buy_weighted_sum / buy_total_vol;
        double new_sl = NormalizeDouble(avg_buy + (inp_be_offset * _Point), _Digits);
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

        detail_str += StringFormat("🔵 <b>BUY %s</b> (Avg: <code>%s</code>)\n", _Symbol, DoubleToString(avg_buy, _Digits));

        // Kiểm tra điều kiện StopLevel so với Bid
        if(new_sl < bid && (bid - new_sl) >= min_stop_dist) {
            for(int k = 0; k < total_buy_count; k++) {
                ulong ptk = buy_tickets[k];
                if(!PositionSelectByTicket(ptk)) continue;

                obj_trade.PositionModify(ptk, new_sl, PositionGetDouble(POSITION_TP));
                detail_str += StringFormat("   • #%I64u -> SL: <code>%s</code> ✅\n", ptk, DoubleToString(new_sl, _Digits));
            }
        } else {
            detail_str += StringFormat("   • ⚠️ Không thể đặt SL <code>%s</code> (Quá sát Bid: <code>%s</code>)\n",
                                       DoubleToString(new_sl, _Digits), DoubleToString(bid, _Digits));
        }
    }

// 3. Xử lý BE cho vị thế SELL
    if(total_sell_count > 0 && sell_total_vol > 0) {
        double avg_sell = sell_weighted_sum / sell_total_vol;
        double new_sl = NormalizeDouble(avg_sell - (inp_be_offset * _Point), _Digits);
        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        detail_str += StringFormat("🔴 <b>SELL %s</b> (Avg: <code>%s</code>)\n", _Symbol, DoubleToString(avg_sell, _Digits));

        // Kiểm tra điều kiện StopLevel so với Ask
        if(new_sl > ask && (new_sl - ask) >= min_stop_dist) {
            for(int k = 0; k < total_sell_count; k++) {
                ulong ptk = sell_tickets[k];
                if(!PositionSelectByTicket(ptk)) continue;

                obj_trade.PositionModify(ptk, new_sl, PositionGetDouble(POSITION_TP));
                detail_str += StringFormat("   • #%I64u -> SL: <code>%s</code> ✅\n", ptk, DoubleToString(new_sl, _Digits));
            }
        } else {
            detail_str += StringFormat("   • ⚠️ Không thể đặt SL <code>%s</code> (Quá sát Ask: <code>%s</code>)\n",
                                       DoubleToString(new_sl, _Digits), DoubleToString(ask, _Digits));
        }
    }

    obj_trade.SetAsyncMode(false);

// 4. Phản hồi Telegram
    string replyMess = StringFormat("<b>🛡 BREAK-EVEN [%s]</b>\n" +
                                    "Offset: <code>%d points</code>\n" +
                                    "———————————————\n%s", _Symbol, inp_be_offset, detail_str);

    bot.ReplyMessID(chatId, msgId, replyMess, true);
}
//+------------------------------------------------------------------+
