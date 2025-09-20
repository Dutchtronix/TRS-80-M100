// VT52.cs
// Copyright (c) 2016, 2017, 2019, 2020 Kenneth Gober
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Text;
using System.Media;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

namespace Emulator
{
    public partial class Terminal
    {
        // VT52 Emulator
        // References:
        // http://bitsavers.trailing-edge.com/pdf/dec/terminal/vt52/EK-VT5X-OP-001_DECscope_Users_Manual_Mar77.pdf
        // http://bitsavers.trailing-edge.com/pdf/dec/terminal/vt52/EK-VT52-MM-002_maint_Jul78.pdf
        // http://bitsavers.trailing-edge.com/pdf/dec/terminal/vt52/MP00035_VT52schem.pdf

        // Future Improvements / To Do
        // key click
        // accurate bell sound
        // copy key (incl. ESC Z report of printer support) (home or pgup)
        // repeat key (alt)
        // accurate behavior for invalid S1/S2 switch combinations
        // accurate keyboard rollover
        // add command line option for serial connection
        // allow re-use of recent network destinations
        // store previous serial port configuration
        // log to file
        // right click context menu? (if so, move Paste option there)


        // Terminal-MainWindow Interface [Main UI Thread]

        public partial class VT52 : Terminal
        {
            public VT52()
            {
                InitKeyboard();
                InitDisplay();
                InitIO();
                ParseArgs(Program.Args);
            }

            private void ParseArgs(String[] args)
            {
                Int32 ap = 0;
                while (ap < args.Length)
                {
                    String arg = args[ap++];
                    if ((arg != null) && (arg.Length != 0))
                    {
                        Char c = arg[0];
                        if (((c == '-') || (c == '/')) && (arg.Length > 1))
                        {
                            switch (arg[1])
                            {
                                case 'o':
                                case 'O':
                                    arg = arg.Substring(2);
                                    if ((arg.Length == 0) && (ap < args.Length)) arg = args[ap++];
                                    while (arg.Length != 0)
                                    {
                                        if (arg.StartsWith("s+", StringComparison.OrdinalIgnoreCase))
                                        {
                                            mOptSwapDelBS = true;
                                            if (dlgSettings == null) dlgSettings = new SettingsDialog();
                                            dlgSettings.OptSwapDelBS = true;
                                            arg = arg.Substring(2);
                                        }
                                        else if (arg.StartsWith("s-", StringComparison.OrdinalIgnoreCase))
                                        {
                                            mOptSwapDelBS = false;
                                            if (dlgSettings == null) dlgSettings = new SettingsDialog();
                                            dlgSettings.OptSwapDelBS = false;
                                            arg = arg.Substring(2);
                                        }
                                        else if (arg.StartsWith("r+", StringComparison.OrdinalIgnoreCase))
                                        {
                                            mOptAutoRepeat = true;
                                            if (dlgSettings == null) dlgSettings = new SettingsDialog();
                                            dlgSettings.OptAutoRepeat = true;
                                            arg = arg.Substring(2);
                                        }
                                        else if (arg.StartsWith("r-", StringComparison.OrdinalIgnoreCase))
                                        {
                                            mOptAutoRepeat = false;
                                            if (dlgSettings == null) dlgSettings = new SettingsDialog();
                                            dlgSettings.OptAutoRepeat = false;
                                            arg = arg.Substring(2);
                                        }
                                        else if (arg.StartsWith("g+", StringComparison.OrdinalIgnoreCase))
                                        {
                                            mDisplay.GreenFilter = true;
                                            if (dlgSettings == null) dlgSettings = new SettingsDialog();
                                            dlgSettings.OptGreenFilter = true;
                                            arg = arg.Substring(2);
                                        }
                                        else if (arg.StartsWith("g-", StringComparison.OrdinalIgnoreCase))
                                        {
                                            mDisplay.GreenFilter = false;
                                            if (dlgSettings == null) dlgSettings = new SettingsDialog();
                                            dlgSettings.OptGreenFilter = false;
                                            arg = arg.Substring(2);
                                        }
                                        else if (arg.StartsWith("d+", StringComparison.OrdinalIgnoreCase))
                                        {
                                            mOptStretchDisplay = true;
                                            Program.Window.FixedAspectRatio = false;
                                            if (dlgSettings == null) dlgSettings = new SettingsDialog();
                                            dlgSettings.OptStretchDisplay = true;
                                            arg = arg.Substring(2);
                                        }
                                        else if (arg.StartsWith("d-", StringComparison.OrdinalIgnoreCase))
                                        {
                                            mOptStretchDisplay = false;
                                            Program.Window.FixedAspectRatio = true;
                                            if (dlgSettings == null) dlgSettings = new SettingsDialog();
                                            dlgSettings.OptStretchDisplay = false;
                                            arg = arg.Substring(2);
                                        }
                                    }
                                    break;
                                case 'r':
                                case 'R':
                                    arg = arg.Substring(2);
                                    if ((arg.Length == 0) && (ap < args.Length)) arg = args[ap++];
                                    if (dlgConnection == null) dlgConnection = new ConnectionDialog();
                                    dlgConnection.Set(typeof(IO.RawTCP), arg);
                                    mUART.IO = ConnectRawTCP(dlgConnection.Options);
                                    break;
                                case 't':
                                case 'T':
                                    arg = arg.Substring(2);
                                    if ((arg.Length == 0) && (ap < args.Length)) arg = args[ap++];
                                    if (dlgConnection == null) dlgConnection = new ConnectionDialog();
                                    dlgConnection.Set(typeof(IO.Telnet), arg);
                                    mUART.IO = ConnectTelnet(dlgConnection.Options);
                                    break;
                            }
                        }
                    }
                }
            }
        }


        // Terminal Input (Keyboard & Switches) [Main UI Thread]

        // VT52 Key Mappings:
        //   most ASCII character keys function as labeled on PC
        //   note: VT52 "[]" and "{}" keys differ from PC "[{" and "]}" keys
        //   Linefeed = Insert      PF1 = F1 (also NumLock)
        //   Break = End            PF2 = F2 (also Num/)
        //   Scroll = PgDn          PF3 = F3 (also Num*)
        //   Up = Up (also Num- in Alternate Keypad Mode)
        //   Down = Down (also Shift + Num+ in Alternate Keypad Mode)
        //   Right = Right (also Num+ in Alternate Keypad Mode)
        //   Left = Left (also Shift + NumEnter in Alternate Keypad Mode)
        // Brightness Slider: F11 (decrease) & F12 (increase)
        // Switch S1 (1-7) - Transmit Speed
        //   1 = Off-Line (Transmit at S2 Speed)
        //   2 = Full Duplex with Local Copy (Transmit at S2 Speed)
        //   3 = Full Duplex (Transmit at S2 Speed)
        //   4 = 300 Baud Transmit
        //   5 = 150 Baud Transmit
        //   6 = 75 Baud Transmit
        //   7 = 4800 Baud Transmit
        //   8 = Line Speed (emulator only, not a real VT52 capability)
        // Switch S2 (A-G) - Receive Speed
        //   A = (Receive at S1 Speed) with Local Copy
        //   B = 110 Baud Receive
        //   C = (Receive at S1 Speed)
        //   D = 600 Baud Receive
        //   E = 1200 Baud Receive
        //   F = 2400 Baud Receive
        //   G = 9600 Baud Receive
        //   H = 19200 Baud Receive (emulator only, not a real VT52 capability)
        // invalid combinations: 1A 1C 2A 2C 3A 3C
        // "Local Copy" means local echo (UART tx wired to rx)

        public partial class VT52
        {
            private List<VK> mKeys;                 // keys currently pressed
            private Boolean mShift;                 // Shift is pressed
            private Boolean mCtrl;                  // Ctrl is pressed
            private Boolean mCaps;                  // Caps Lock is enabled
            private volatile Boolean mKeypadMode;   // Alternate Keypad Mode enabled
            private Boolean mOptSwapDelBS;          // swap Delete and Backspace keys
            private Boolean mOptAutoRepeat;         // enable automatic key repeat
            private Boolean mOptStretchDisplay;     // allow variable aspect ratio
            private SettingsDialog dlgSettings;
            private ConnectionDialog dlgConnection;

            private void InitKeyboard()
            {
                mKeys = new List<VK>();
                mCaps = Console.CapsLock;
                mOptSwapDelBS = true;
            }

            public Boolean KeypadMode
            {
                get { return mKeypadMode; }
                set { mKeypadMode = value; }
            }

            public override Boolean KeyEvent(Int32 msgId, IntPtr wParam, IntPtr lParam)
            {
                switch (msgId)
                {
                    case 0x0100:    // WM_KEYDOWN
                        return KeyDown(wParam, lParam);
                    case 0x0101:    // WM_KEYUP
                        return KeyUp(wParam, lParam);
                    default:
                        return false;
                }
            }

            public override Boolean MenuEvent(Int32 msgId, IntPtr wParam, IntPtr lParam)
            {
                Debug.WriteLine("MenuEvent: msgId=0x{0:x4} wParam=0x{1:x4} lParam=0x{2:x8}", msgId, (Int32)wParam, (Int32)lParam);
                if (msgId == 0x0112) // WM_SYSCOMMAND
                {
                    switch ((Int32)wParam)
                    {
                        case 5: // Settings (F5)
                            AskSettings();
                            return true;
                        case 6: // Connection (F6)
                            AskConnection();
                            return true;
                        case 11: // Brightness - (F11)
                            LowerBrightness();
                            return true;
                        case 12: // Brightness + (F12)
                            RaiseBrightness();
                            return true;
                        case 99: // About
                            String v = Assembly.GetExecutingAssembly().GetName().Version.ToString();
                            System.Windows.Forms.MessageBox.Show(String.Concat(Program.Name, " v", v, "\r\nCopyright © Kenneth Gober 2016, 2017, 2019\r\nhttps://github.com/kgober/VT52"), String.Concat("About ", Program.Name));
                            return true;
                        default:
                            return false;
                    }
                }
                else
                {
                    return false;
                }
            }

            public override void Paste(string text)
            {
                foreach (Char c in text)
                {
                    if (c < 128) Input(c);
                }
            }

            private Boolean KeyDown(IntPtr wParam, IntPtr lParam)
            {
                Char c;
                VK k = MapKey(wParam, lParam);
                Int32 l = lParam.ToInt32();
                Debug.WriteLine("KeyDown: wParam={0:X8} lParam={1:X8} vk={2} (0x{3:X2}) num={4}", (Int32)wParam, l, k.ToString(), (Int32)k, Console.NumberLock);

                // prevent NumLock key from changing NumLock state by pressing it again
                if (k == VK.NUMLOCK)
                {
                    if (((l >> 16) & 0xFF) == 0) return true;
                    Win32.keybd_event(k, 0, KEYEVENTF.EXTENDEDKEY | KEYEVENTF.KEYUP, 0);
                    Win32.keybd_event(k, 0, KEYEVENTF.EXTENDEDKEY, 0);
                }

                // auto-repeat always enabled for F11 & F12
                if (k == VK.F11) { LowerBrightness(); return true; }
                if (k == VK.F12) { RaiseBrightness(); return true; }

                if (!mKeys.Contains(k))
                    mKeys.Add(k);
                else if (((l & 0x40000000) != 0) && (mOptAutoRepeat == false))
                    return true;

                if ((k >= VK.A) && (k <= VK.Z))
                {
                    c = (Char)(k - VK.A + ((mShift || mCaps) ? 'A' : 'a'));
                    Input((mCtrl) ? (Char)(c & 31) : c);
                    return true;
                }
                if ((k >= VK.K0) && (k <= VK.K9))
                {
                    c = (Char)(k - VK.K0 + '0');
                    if (mShift)
                    {
                        switch (c)
                        {
                            case '1': c = '!'; break;
                            case '2': c = '@'; break;
                            case '3': c = '#'; break;
                            case '4': c = '$'; break;
                            case '5': c = '%'; break;
                            case '6': c = '^'; break;
                            case '7': c = '&'; break;
                            case '8': c = '*'; break;
                            case '9': c = '('; break;
                            case '0': c = ')'; break;
                        }
                    }
                    Input((mCtrl) ? (Char)(c & 31) : c);
                    return true;
                }
                if ((k >= VK.NUMPAD0) && (k <= VK.NUMPAD9))
                {
                    c = (Char)(k - VK.NUMPAD0 + '0');
                    if (!mKeypadMode)
                    {
                        Input(c);
                        return true;
                    }
                    switch (c)
                    {
                        case '0': Input("\x001B?p"); break;
                        case '1': Input("\x001B?q"); break;
                        case '2': Input("\x001B?r"); break;
                        case '3': Input("\x001B?s"); break;
                        case '4': Input("\x001B?t"); break;
                        case '5': Input("\x001B?u"); break;
                        case '6': Input("\x001B?v"); break;
                        case '7': Input("\x001B?w"); break;
                        case '8': Input("\x001B?x"); break;
                        case '9': Input("\x001B?y"); break;
                    }
                    return true;
                }

                switch (k)
                {
                    case VK.LSHIFT:
                    case VK.RSHIFT:
                        mShift = true;
                        return true;
                    case VK.LCONTROL:
                    case VK.RCONTROL:
                        mCtrl = true;
                        return true;
                    case VK.CAPITAL:
                        mCaps = !mCaps;
                        return true;
                    case VK.SPACE:
                        Input((mCtrl) ? '\x00' : ' ');
                        return true;
                    case VK.RETURN:
                        Input('\r');
                        return true;
                    case VK.INSERT:
                        Input('\n');
                        return true;
                    case VK.BACK:
                        Input('\b');
                        return true;
                    case VK.TAB:
                        Input('\t');
                        return true;
                    case VK.ESCAPE:
                        Input('\x1B');
                        return true;
                    case VK.DELETE:
                        Input((mCtrl) ? '\x1F' : '\x7F');
                        return true;
                    case VK.COMMA:
                        c = (mShift) ? '<' : ',';
                        Input((mCtrl) ? (Char)(c & 31) : c);
                        return true;
                    case VK.PERIOD:
                        c = (mShift) ? '>' : '.';
                        Input((mCtrl) ? (Char)(c & 31) : c);
                        return true;
                    case VK.SLASH:
                        c = (mShift) ? '?' : '/';
                        Input((mCtrl) ? (Char)(c & 31) : c);
                        return true;
                    case VK.SEMICOLON:
                        c = (mShift) ? ':' : ';';
                        Input((mCtrl) ? (Char)(c & 31) : c);
                        return true;
                    case VK.QUOTE:
                        c = (mShift) ? '"' : '\'';
                        Input((mCtrl) ? (Char)(c & 31) : c);
                        return true;
                    case VK.MINUS:
                        c = (mShift) ? '_' : '-';
                        Input((mCtrl) ? (Char)(c & 31) : c);
                        return true;
                    case VK.EQUAL:
                        c = (mShift) ? '+' : '=';
                        Input((mCtrl) ? (Char)(c & 31) : c);
                        return true;
                    case VK.TILDE:
                        c = (mShift) ? '~' : '`';
                        Input((mCtrl) ? (Char)(c & 31) : c);
                        return true;
                    case VK.BACKSLASH:
                        c = (mShift) ? '|' : '\\';
                        Input((mCtrl) ? (Char)(c & 31) : c);
                        return true;
                    case VK.LBRACKET:
                        c = (mShift) ? '{' : '['; // on a real VT52, this is [ (unshifted) or ] (shifted)
                        Input((mCtrl) ? (Char)(c & 31) : c);
                        return true;
                    case VK.RBRACKET:
                        c = (mShift) ? '}' : ']'; // on a real VT52, this is { (unshifted) or } (shifted)
                        Input((mCtrl) ? (Char)(c & 31) : c);
                        return true;
                    case VK.UP:
                        Input("\x001BA");
                        return true;
                    case VK.DOWN:
                        Input("\x001BB");
                        return true;
                    case VK.RIGHT:
                        Input("\x001BC");
                        return true;
                    case VK.LEFT:
                        Input("\x001BD");
                        return true;
                    case VK.NUMLOCK:
                    case VK.F1:
                        Input("\x001BP");
                        return true;
                    case VK.DIVIDE:
                    case VK.F2:
                        Input("\x001BQ");
                        return true;
                    case VK.MULTIPLY:
                    case VK.F3:
                        Input("\x001BR");
                        return true;
                    case VK.SUBTRACT:
                        Input((mKeypadMode) ? "\x001BA" : "-");
                        return true;
                    case VK.ADD:
                        Input((mKeypadMode) ? ((mShift) ? "\x001BB" : "\x001BC") : "+");
                        return true;
                    case VK.ENTER:
                        Input((mKeypadMode) ? ((mShift) ? "\x001BD" : "\x001B?M") : "\r");
                        return true;
                    case VK.DECIMAL:
                        Input((mKeypadMode) ? "\x001B?n" : ".");
                        return true;
                    case VK.END:
                        SetBreakState(true);
                        return true;
                    case VK.NEXT:
                        AllowScroll((mShift) ? 24 : 1);
                        return true;
                    case VK.F5:
                        AskSettings();
                        return true;
                    case VK.F6:
                        AskConnection();
                        return true;
                }
                return false;
            }

            private Boolean KeyUp(IntPtr wParam, IntPtr lParam)
            {
                VK k = MapKey(wParam, lParam);
                Int32 l = (Int32)(lParam.ToInt64() & 0x00000000FFFFFFFF);
                Debug.WriteLine("KeyUp: wParam={0:X8} lParam={1:X8} vk={2} (0x{3:X2}) num={4}", (Int32)wParam, l, k.ToString(), (Int32)k, Console.NumberLock);
                if (mKeys.Contains(k)) mKeys.Remove(k);

                if ((k >= VK.A) && (k <= VK.Z)) return true;
                if ((k >= VK.K0) && (k <= VK.K9)) return true;
                if ((k >= VK.NUMPAD0) && (k <= VK.NUMPAD9)) return true;

                switch (k)
                {
                    case VK.LSHIFT:
                        mShift = mKeys.Contains(VK.RSHIFT);
                        return true;
                    case VK.RSHIFT:
                        mShift = mKeys.Contains(VK.LSHIFT);
                        return true;
                    case VK.LCONTROL:
                        mCtrl = mKeys.Contains(VK.RCONTROL);
                        return true;
                    case VK.RCONTROL:
                        mCtrl = mKeys.Contains(VK.LCONTROL);
                        return true;
                    case VK.CAPITAL:
                        mCaps = Console.CapsLock;
                        return true;
                    case VK.SPACE:
                    case VK.RETURN:
                    case VK.INSERT:
                    case VK.BACK:
                    case VK.TAB:
                    case VK.ESCAPE:
                    case VK.DELETE:
                    case VK.COMMA:
                    case VK.PERIOD:
                    case VK.SLASH:
                    case VK.SEMICOLON:
                    case VK.QUOTE:
                    case VK.MINUS:
                    case VK.EQUAL:
                    case VK.TILDE:
                    case VK.BACKSLASH:
                    case VK.LBRACKET:
                    case VK.RBRACKET:
                    case VK.UP:
                    case VK.DOWN:
                    case VK.RIGHT:
                    case VK.LEFT:
                    case VK.NUMLOCK:
                    case VK.F1:
                    case VK.DIVIDE:
                    case VK.F2:
                    case VK.MULTIPLY:
                    case VK.F3:
                    case VK.SUBTRACT:
                    case VK.ADD:
                    case VK.ENTER:
                    case VK.DECIMAL:
                    case VK.NEXT:
                    case VK.F5:
                    case VK.F6:
                    case VK.F11:
                    case VK.F12:
                        return true;
                    case VK.END:
                        SetBreakState(false);
                        return true;
                }
                return false;
            }

            private VK MapKey(IntPtr wParam, IntPtr lParam)
            {
                VK k = (VK)wParam;
                Int32 l = (Int32)(lParam.ToInt64() & 0x00000000FFFFFFFF);
                switch (k)
                {
                    case VK.SHIFT:
                        return (VK)Win32.MapVirtualKey((UInt32)((l & 0x00FF0000) >> 16), MAPVK.VSC_TO_VK_EX);
                    case VK.CONTROL:
                        return ((l & 0x01000000) == 0) ? VK.LCONTROL : VK.RCONTROL;
                    case VK.ALT:
                        return ((l & 0x01000000) == 0) ? VK.LALT : VK.RALT;
                    case VK.RETURN:
                        return ((l & 0x01000000) == 0) ? VK.RETURN : VK.ENTER;
                    case VK.BACK:
                        return (mOptSwapDelBS) ? VK.DELETE : VK.BACK;
                    case VK.DELETE:
                        return (mOptSwapDelBS) ? VK.BACK : VK.DELETE;
                    default:
                        return k;
                }
            }

            private void Input(String s)
            {
                if (s == null) return;
                for (Int32 i = 0; i < s.Length; i++) Send((Byte)s[i]);
            }

            private void Input(Char c)
            {
                Send((Byte)c);
            }

            public void AskSettings()
            {
                if (dlgSettings == null) dlgSettings = new SettingsDialog();
                dlgSettings.ShowDialog();
                if (!dlgSettings.OK) return;

                if (dlgSettings.OptSwapDelBS != mOptSwapDelBS)
                {
                    if (mKeys.Contains(VK.BACK)) mKeys.Remove(VK.BACK);
                    if (mKeys.Contains(VK.DELETE)) mKeys.Remove(VK.DELETE);
                    mOptSwapDelBS = dlgSettings.OptSwapDelBS;
                }
                mOptAutoRepeat = dlgSettings.OptAutoRepeat;
                mDisplay.GreenFilter = dlgSettings.OptGreenFilter;
                if (dlgSettings.OptStretchDisplay != mOptStretchDisplay)
                {
                    Program.Window.FixedAspectRatio = !dlgSettings.OptStretchDisplay;
                    mOptStretchDisplay = dlgSettings.OptStretchDisplay;
                }

                Int32 t = -1;
                switch (dlgSettings.S1)
                {
                    case '4': t = 300; break;
                    case '5': t = 150; break;
                    case '6': t = 75; break;
                    case '7': t = 4800; break;
                    case '8': t = 0; break;
                }
                Int32 r = -1;
                switch (dlgSettings.S2)
                {
                    case 'A': r = t; break;
                    case 'B': r = 110; break;
                    case 'C': r = t; break;
                    case 'D': r = 600; break;
                    case 'E': r = 1200; break;
                    case 'F': r = 2400; break;
                    case 'G': r = 9600; break;
                    case 'H': r = 19200; break;
                }
                switch (dlgSettings.S1)
                {
                    case '1': t = r; break;
                    case '2': t = r; break;
                    case '3': t = r; break;
                }
                if (t == -1) return;
                if (r == -1) return;
                SetTransmitSpeed(t);
                SetReceiveSpeed(r);
                SetLocalEcho((dlgSettings.S1 == '2') || (dlgSettings.S2 == 'A'));
                SetTransmitParity(dlgSettings.Parity);
            }

            public void AskConnection()
            {
                if (dlgConnection == null) dlgConnection = new ConnectionDialog();
                dlgConnection.ShowDialog();
                if (!dlgConnection.OK) return;
                if (dlgConnection.IOAdapter == typeof(IO.Loopback))
                {
                    mUART.IO = ConnectLoopback(dlgConnection.Options);
                }
                else if (dlgConnection.IOAdapter == typeof(IO.Serial))
                {
                    mUART.IO = ConnectSerial(dlgConnection.Options);
                }
                else if (dlgConnection.IOAdapter == typeof(IO.Telnet))
                {
                    mUART.IO = ConnectTelnet(dlgConnection.Options);
                }
                else if (dlgConnection.IOAdapter == typeof(IO.RawTCP))
                {
                    mUART.IO = ConnectRawTCP(dlgConnection.Options);
                }
            }

            private IO ConnectLoopback(String options)
            {
                if (mUART.IO is IO.Loopback) return mUART.IO;
                try
                {
                    IO.Loopback X = new IO.Loopback(options);
                    String s = String.Concat(Program.Name, " - ", X.ConnectionString);
                    if (String.Compare(s, mCaption) != 0)
                    {
                        mCaption = s;
                        mCaptionDirty = true;
                    }
                    return X;
                }
                catch (Exception ex)
                {
                    System.Windows.Forms.MessageBox.Show(ex.Message);
                    return mUART.IO;
                }
            }

            private IO ConnectSerial(String options)
            {
                if ((mUART.IO is IO.Serial) && (String.Compare(mUART.IO.Options, options) == 0)) return mUART.IO;
                try
                {
                    IO.Serial X = new IO.Serial(options);
                    String s = String.Concat(Program.Name, " - ", X.ConnectionString);
                    if (String.Compare(s, mCaption) != 0)
                    {
                        mCaption = s;
                        mCaptionDirty = true;
                    }
                    return X;
                }
                catch (Exception ex)
                {
                    System.Windows.Forms.MessageBox.Show(ex.Message);
                    return mUART.IO;
                }
            }

            private IO ConnectTelnet(String options)
            {
                if ((mUART.IO is IO.Telnet) && (String.Compare(mUART.IO.Options, options) == 0)) return mUART.IO;
                try
                {
                    IO.Telnet X = new IO.Telnet(options, mUART.ReceiveSpeed, mUART.TransmitSpeed, Display.COLS, Display.ROWS, "DEC-VT52", "VT52");
                    String s = String.Concat(Program.Name, " - ", X.ConnectionString);
                    if (String.Compare(s, mCaption) != 0)
                    {
                        mCaption = s;
                        mCaptionDirty = true;
                    }
                    return X;
                }
                catch (Exception ex)
                {
                    System.Windows.Forms.MessageBox.Show(ex.Message);
                    return mUART.IO;
                }
            }

            private IO ConnectRawTCP(String options)
            {
                if ((mUART.IO is IO.RawTCP) && (String.Compare(mUART.IO.Options, options) == 0)) return mUART.IO;
                try
                {
                    IO.RawTCP X = new IO.RawTCP(options);
                    String s = String.Concat(Program.Name, " - ", X.ConnectionString);
                    if (String.Compare(s, mCaption) != 0)
                    {
                        mCaption = s;
                        mCaptionDirty = true;
                    }
                    return X;
                }
                catch (Exception ex)
                {
                    System.Windows.Forms.MessageBox.Show(ex.Message);
                    return mUART.IO;
                }
            }
        }


        // Terminal Output (Display & Bell)

        public partial class VT52
        {
            private Display mDisplay;
            private Queue<Byte> mSilo;              // buffered bytes received from UART
            private Int32 mHoldCount;               // number of scrolls until Hold Screen pauses (0 = pausing)
            private Int32 mEsc;                     // processing state for ESC sequences


            private Byte ch2, ch3, ch4;   // storage for escape sequence characters
            private Int32 row = 0, col = 0;

            private Boolean mGraphicsMode;          // Graphics Mode enabled

            // called by main UI thread via constructor
            private void InitDisplay()
            {
                mDisplay = new Display(this);
                mSilo = new Queue<Byte>(13);
                mHoldCount = -1;
            }

            // called by main UI thread
            public override Bitmap Bitmap
            {
                get { return mDisplay.Bitmap; }
            }

            // called by main UI thread
            public override Boolean BitmapDirty
            {
                get { return mDisplay.BitmapDirty; }
                set { mDisplay.BitmapDirty = value; }
            }

            // called by main UI thread via KeyDown() or system menu
            public void LowerBrightness()
            {
                mDisplay.ChangeBrightness(-5);
            }

            // called by main UI thread via KeyDown() or system menu
            public void RaiseBrightness()
            {
                mDisplay.ChangeBrightness(5);
            }

            // called by main UI thread via KeyDown()
            private void AllowScroll(Int32 lines)
            {
                lock (mSilo)
                {
                    if (mHoldCount == 0)
                    {
                        mHoldCount += lines;
                        while ((mHoldCount != 0) && (mSilo.Count != 0)) Output(mSilo.Dequeue());
                        if (mHoldCount != 0) Send(0x11); // XON
                    }
                }
            }

            // called by worker thread
            private void Recv(Byte c)
            {
                Debug.WriteLine("Recv: {0} ({1:D0}/0x{1:X2})", (Char)c, c);
                // if Hold Screen is pausing, divert received chars to silo
                lock (mSilo)
                {
                    if (mHoldCount == 0)
                    {
                        if (mSilo.Count == 13)
                        {
                            // prevent silo overflow by allowing 1 scroll
                            mHoldCount++;
                            while ((mHoldCount != 0) && (mSilo.Count != 0)) Output(mSilo.Dequeue());
                            if ((mHoldCount != 0) && (c != 0x0A)) Send(0x11); // XON
                        }
                        if (mHoldCount == 0)
                        {
                            mSilo.Enqueue(c);
                            return;
                        }
                    }
                }

                //while (mDisplay.mCursorActive) { };
                //mDisplay.CursorMaskOn();
                mDisplay.clearCursor();
                mDisplay.TurnOffCursor();
                Output(c);
                mDisplay.TurnOnCursor();
                //mDisplay.CursorMaskOff();

                mDisplay.ToggleCursor();

            }

            private void Output(Byte c)
            {
                // mEsc indicates escape sequence pending and number of escape characters

                Int32 nx, ny;
                Boolean temp;
                    switch (mEsc)
                    {
                        case 0: // regular ASCII characters & control characters (non-escaped)
                            switch ((Char)c)           
                            {
                                case '\x1B': // ESC - Escape Sequence
                                    mEsc = 1;       // indicate escape sequence detected
                                    return;
                                case '\r': // CR - Carriage Return
                                    mDisplay.MoveCursorAbs(0, mDisplay.CursorY);
                                    mEsc = 0;       // for any sequence indicate no escape sequence pending
                                    return;
                                case '\n': // LF - Line Feed
                                    ny = mDisplay.CursorY + 1;  

                                    if (ny >= (Display.ROWS - mDisplay.lockLine))
                                    {
                                     //   if (mHoldCount > 0) mHoldCount--;
                                     //   if (mHoldCount == 0)
                                     //   {
                                     //       mSilo.Enqueue(c);
                                     //       Send(0x13); // XOFF
                                     //       return;
                                     //   }

                                        mDisplay.ScrollUpY(0,ny - 1);
                                        ny = Display.ROWS - 1 - mDisplay.lockLine;
                                    }
                                    mDisplay.MoveCursorAbs(mDisplay.CursorX, ny);
                                    mEsc = 0;       // for any sequence indicate no escape sequence pending
                                    return;
                                case '\b': // BS - Backspace

                                    mDisplay.MoveCursorRel(-1, 0);
                                    mEsc = 0;       // for any sequence indicate no escape sequence pending
                                    return;
                                case '\t': // HT - Horizontal Tab

                                    if (mDisplay.CursorX >= 72)
                                        mDisplay.MoveCursorRel(1, 0);
                                    else
                                        mDisplay.MoveCursorRel(8 - (mDisplay.CursorX % 8), 0);
                                    mEsc = 0;       // for any sequence indicate no escape sequence pending
                                    return;
                                case '\a': // BEL - Ring the Bell
                                    mDisplay.Beep();
                                    mEsc = 0;       // for any sequence indicate no escape sequence pending
                                    return;
                            }

                            if (c > 31)
                            {
                                mDisplay.Char = (Byte)c;
                                if (mDisplay.CursorX >= (Display.COLS - 1))
                                {
                                    Output((Byte)'\r');
                                    Output((Byte)'\n');
                                }
                                else
                                {
                                    mDisplay.MoveCursorRel(1, 0);
                                }
                            }
                            mEsc = 0;
                            return;


                        case 1: // ESC - Escape Sequence detected
                            ch2 = 0;
                            ch3 = 0;
                            ch4 = 0;
                            row = 0;
                            col = 0;
                        // initialize the storage characters
                        // ESC-c sequence ignored here.
                        // Should be RIS: "Reset Terminal to Initial State"
#if false
                        if (((Char)c) == '[') mEsc = 2;
                            else mEsc = 0;
                            return;
#else
                            if (((Char)c) == '[')
                                mEsc = 2;
                            else if (((Char)c) == 'c') {
                                //Clear Screen
                                for (Int32 y = 0; y < Display.ROWS; y++) {
                                    for (Int32 x = 0; x < Display.COLS; x++) {
                                        mDisplay.Char = (Byte)' ';
                                        mDisplay.move_cursor(x, y);
                                    }
                                }
                                mDisplay.MoveCursorAbs(0, 0);
                                mEsc = 0;
                            }
                            else {
                                // ignore other characters
                                mEsc = 0;
                            }
                            return;
#endif

                    case 2:     // check for 3 byte escape sequences
                                ch2 = c;
                                row = c - 48;
                                switch ((Char)c)
                                {
                                    case 'H': // ESC[H - Cursor Home
                                        mEsc = 0;
                                        mDisplay.MoveCursorAbs(0, 0);
                                        return;
                                    case 'T': // ESC[T - lock line 24 (8) 
                                        mEsc = 0;
                                        mDisplay.lockLine = 1;
                                        return;
                                    case 'U': // ESC[U - unlock line 24 (8)
                                        mEsc = 0;
                                        mDisplay.lockLine = 0;
                                        return;
                                    case 'V': // ESC[V - lock scroll
                                        mEsc = 0;
                                        mDisplay.scrollLock = true;
                                        return;
                                    case 'W': // ESC[W - unlock scroll
                                        mEsc = 0;
                                        mDisplay.scrollLock = false; ;
                                        return;
                                    case 'M': // ESC[M - delete line @ cursor and scroll up
                                        mEsc = 0;
                                        temp = mDisplay.scrollLock;
                                        mDisplay.scrollLock = false;
                                        //for (Int32 x = 0; x < Display.COLS; x++) mDisplay[x, mDisplay.CursorY] = 32;
                                        mDisplay.ScrollUpY(mDisplay.CursorY, Display.ROWS - 1 - mDisplay.lockLine);
                                        mDisplay.scrollLock = temp;
                                        return;
                                    case 'L': // ESC[L - insert blank line
                                        mEsc = 0;
                                        temp = mDisplay.scrollLock;
                                        mDisplay.scrollLock = false;
                                        mDisplay.ScrollDownY(mDisplay.CursorY, Display.ROWS - 1 - mDisplay.lockLine);
                                        mDisplay.scrollLock = temp;
                                        return;
                                    case 'K': // ESC[K - Erase to End-of-Line
                                        mEsc = 0;
                                        for (Int32 x = mDisplay.CursorX; x < Display.COLS; x++) mDisplay[x, mDisplay.CursorY] = 32;
                                        return;
                                    case 'A': // ESC[A - Cursor Up
                                        mEsc = 0;
                                        mDisplay.MoveCursorRel(0, -1);
                                        return;
                                    case 'B': // ESC[B - Cursor Down
                                        mEsc = 0;
                                        mDisplay.MoveCursorRel(0, 1);
                                        return;
                                    case 'C': // ESC[C - Cursor Right
                                        mEsc = 0;
                                        mDisplay.MoveCursorRel(1, 0);
                                        return;
                                    case 'D': // ESC[D - Cursor Left
                                        mEsc = 0;
                                        mDisplay.MoveCursorRel(-1, 0);
                                        return;
                                    case 'J': // ESC[J - erase to end of screen
                                        mEsc = 0;
                                        for (Int32 x = mDisplay.CursorX; x < Display.COLS; x++) mDisplay[x, mDisplay.CursorY] = 32;
                                        for (Int32 y = mDisplay.CursorY + 1; y < Display.ROWS; y++)
                                        {
                                            for (Int32 x = 0; x < Display.COLS; x++) mDisplay[x, y] = 32;
                                        }
                                        return;

                                    default:   // invalid escape sequence or could be a location command, figure it out next
                                        mEsc = 3;
                                        return;
                                }

                            case 3:         // check for 3+ byte escape sequences
                                ch3 = c;    // got 2nd possible data byte
                                if (c == ';')   {             // ESC[@;@@f
                                   mEsc = 6;                   // skip to 6 test here for valid location commmand
                                   col = 0;
                                    return;
                                 }
                                row = 10 * row + c - 48;
                                if (((Char)ch2 == '2') && ((Char)c == 'J'))     // ESC[2J - Erase Screen
                                {
                                    mEsc = 0;
                                    for (Int32 y = 0; y < Display.ROWS; y++)
                                    {
                                        for (Int32 x = 0; x < Display.COLS; x++)
                                        {
                                            mDisplay.Char = (Byte)' ';
                                            mDisplay.move_cursor(x, y);
                                        }
                                    }
                                    return;
                                }

                                if (((Char)ch2 == '2') && ((Char)c == 'K'))      // ESC[2K - erase current line
                                {
                                    mEsc = 0;
                                    ny = mDisplay.CursorY;
                                    for (Int32 x = 0; x < Display.COLS; x++) mDisplay[x, ny] = 32;
                                    return;
                                }

                                if (((Char)ch2 == '7') && ((Char)c == 'm'))      // ESC[7m - set reverse character
                                {
                                    mEsc = 0;
                                    mDisplay.revVideo = 0xFF;     // enable reverse video
                                    return;
                                }

                                if (((Char)ch2 == '0') && ((Char)c == 'm'))      // ESC[0m - reset reverse character
                                {
                                    mEsc = 0;
                                    mDisplay.revVideo = 0x00;        // reset reverse video
                                    return;
                                }
                                mEsc = 4;       // could be a longer sequence
                                return;

                            case 4:         // check for 4+ byte escape sequences
                                ch4 = c;                        // could be data or ;
                                if ((Char)c == ';')           // ESC[@@;@@f
                                {
                                    mEsc = 6;                   // skip to 6 test here for valid location commmand
                                    col = 0;
                                    return;
                                }

                                if ((Char)ch2 == 'Y')              // ESC Y <row> <col> - Direct Cursor Addressing
                                {
                                    nx = ch3 - 32;
                                    ny = ch4 - 32;
                                    mDisplay.move_cursor(nx, ny);
                                    mEsc = 0;
                                    return;
                                }
                                if (((Char)ch2 == '?') && ((Char)ch3 == '2') && ((Char)ch4 == '5'))     // ESC[?25h, ESC[?25h
                                {
                                    mEsc = 5;   // ESC[?25 recognized
                                    return;
                                }

                                row = 10 * row + c - 48;
                                col = 0;
                                mEsc = 5;
                                return;

                            case 5:         // check for 5 byte escape sequences                       
                                if ((Char)c == ';')           // ESC[@@;@@f
                                {
                                    mEsc = 6;                   // skip to 6 test here for valid location commmand
                                    col = 0;

                                    return;
                                }

                                if (((Char)ch2 == '?') && ((Char)ch3 == '2') && ((Char)ch4 == '5') && ((Char)c == 'h'))  // ESC[?25h
                                {
                                    mEsc = 0;   // turn on cursor
                                    mDisplay.cursorOff = false;
                                    return;
                                }
                                if (((Char)ch2 == '?') && ((Char)ch3 == '2') && ((Char)ch4 == '5') && ((Char)c == 'l'))  // ESC[?25l
                                {
                                    mEsc = 0;   // turn off cursor
                                    mDisplay.cursorOff = true;
                                    return;
                                }

                                mEsc = 0;  // broken sequence
                                return;

                            case 6:         // check for 4+ byte escape sequences
                                col = c - 48;
                                mEsc = 7;
                                return;

                            case 7:         // check for 4+ byte escape sequences
                                if ((char)c == 'f') {
                                    mDisplay.move_cursor(col - 1, row - 1);
                                    mEsc = 0;                   // test here for valid location commmand
                                    return;
                                }
                                else {
                                  col = 10 * col + c - 48;
                                }
                                mEsc = 8;
                                return;

                            case 8:
                                if ((Char)c == 'f')
                                {
                                    mDisplay.move_cursor(col - 1, row - 1);
                                    mEsc = 0;                   // test here for valid location commmand
                                    return;
                                }
                                col = 10 * col + c - 48;

                                mEsc = 9;
                                return;

                            case 9:
                                if ((Char)c == 'f')
                                {
                                    mDisplay.move_cursor(col - 1, row - 1);
                                    mEsc = 0;                   // test here for valid location commmand
                                    return;
                                }

                                mEsc = 0;       // bad sequence
                                return;

                            default:       // not a valid sequence
                                mEsc = 0;
                                return;
                            }
                
                
            }



            // 80x24 character cells, each cell is 10 raster lines tall and 9 dots wide.
            // top raster line is blank, next 8 are for character, last is cursor line.
            // To simulate the raster, a 1 pixel gap is left between each raster line.
            // P4 phosphor (white).

            private class Display
            {
                public const Int32 ROWS = 24;
                public const Int32 COLS = 80;
                public Byte revVideo;       // local variables
                public Boolean cursorOff;

                private const Int32 PIXELS_PER_ROW = 20;
                private const Int32 PIXELS_PER_COL = 9;

                private VT52 mVT52;                     // for calling parent's methods
                private UInt32[] mPixMap;               // pixels
                private GCHandle mPixMapHandle;         // handle for pinned pixels
                private Bitmap mBitmap;                 // bitmap interface
                public volatile Boolean mBitmapDirty;  // true if bitmap has changed
                public Byte[] mChars;                  // characters on screen
                private Int32 mX, mY;                   // cursor position
                public System.Threading.Timer mCursorTimer;             // cursor blink timer
                private Boolean mCursorVisible;         // whether cursor is currently visible
                private Int32 mBrightness;              // brightness (0-100)
                public UInt32 mOffColor;               // pixel 'off' color
                private UInt32 mOnColor;                // pixel 'on' color
                private Boolean mOptGreenFilter;        // simulate green CRT filter
                public Boolean scrollLock;
                public Int32 lockLine;


                public Display(VT52 parent)
                {
                    mVT52 = parent;
                    Int32 x = COLS * PIXELS_PER_COL;
                    Int32 y = ROWS * PIXELS_PER_ROW;
                    mPixMap = new UInt32[x * y];
                    mPixMapHandle = GCHandle.Alloc(mPixMap, GCHandleType.Pinned);
                    mBitmap = new Bitmap(x, y, x * sizeof(Int32), PixelFormat.Format32bppPArgb, mPixMapHandle.AddrOfPinnedObject());
                    mChars = new Byte[COLS * ROWS];
                    mBrightness = 85;   // 85% is the maximum brightness without blue being oversaturated
                    mOffColor = Color(0);
                    mOnColor = Color(mBrightness);
                    mCursorVisible = false;
                    mCursorTimer = new System.Threading.Timer(CursorTimer_Callback, null, 500, 250); // 4 transitions per second (2 Hz blink rate)
                    revVideo = 0x00;
                    cursorOff = false;

                }

                public Bitmap Bitmap
                {
                    get { return mBitmap; }
                }

                public Boolean BitmapDirty
                {
                    get { return mBitmapDirty; }
                    set { mBitmapDirty = value; }
                }

                public Boolean GreenFilter
                {
                    get
                    {
                        return mOptGreenFilter;
                    }
                    set
                    {
                        if (mOptGreenFilter != value)
                        {
                            mOptGreenFilter = value;
                            ChangeBrightness(0);
                        }
                    }
                }

                public Int32 CursorX
                {
                    get { return mX; }
                }

                public Int32 CursorY
                {
                    get { return mY; }
                }
  
                public Byte Char
                {
                    get { return this[mX, mY]; }
                    set { this[mX, mY] = value; }
                }

                public Byte this[Int32 x, Int32 y]
                {
                    get
                    {
                        if ((x < 0) || (x >= COLS)) throw new ArgumentOutOfRangeException("x");
                        if ((y < 0) || (y >= ROWS)) throw new ArgumentOutOfRangeException("y");
                        return mChars[y * COLS + x];
                    }
                    set
                    {
                        if ((x < 0) || (x >= COLS)) throw new ArgumentOutOfRangeException("x");
                        if ((y < 0) || (y >= ROWS)) throw new ArgumentOutOfRangeException("y");

                        byte rv = revVideo;
                        Int32 p = y * COLS + x;
                        mChars[p] = value;
                        p = value * 8;
                        if (p >= CharGen.Length) return;
                        lock (mBitmap)
                        {
                            x *= PIXELS_PER_COL;
                            y *= PIXELS_PER_ROW;
                            Int32 q = y * COLS * PIXELS_PER_COL + x;        // change 1 to 0
                            Int32 q1 = q + COLS * PIXELS_PER_COL;           // first 3 rows
                            Int32 q2 = q + COLS * PIXELS_PER_COL*2;
                            Int32 q3 = q + COLS * PIXELS_PER_COL*19;        // last 1 rows
                            Byte b = rv;
                            Int32 dx;
                            Byte m;
                            for (dx = 0; dx < 9; dx++)                    // draw first line change 7 to 9
                            {
                                mPixMap[q + dx] = (b == 0) ? mOffColor : mOnColor;
                                mPixMap[q1 + dx] = (b == 0) ? mOffColor : mOnColor;     // draw 2 lines of blank on top
                                mPixMap[q2 + dx] = (b == 0) ? mOffColor : mOnColor;
                                mPixMap[q3 + dx] = (b == 0) ? mOffColor : mOnColor;     // draw 2 lines of blank on bottom
                            }
                            q = q2 + COLS * PIXELS_PER_COL ;                     //  advance q
                            q1 = q + COLS * PIXELS_PER_COL ;                     //  advance q1
                            for (Int32 dy = 0; dy < 8; dy++)                    // 8 pairs of lines
                            {
                                b = (byte)(CharGen[p++] ^ rv);
                                m = 128;
                                for (dx = 0; dx < 8; dx++)
                                {
                                    mPixMap[q + dx] = ((b & m) == 0) ? mOffColor : mOnColor;
                                    mPixMap[q1 + dx] = ((b & m) == 0) ? mOffColor : mOnColor;
                                    m >>= 1;                                        // roll bit
                                }
                                b = rv;
                                mPixMap[q + dx] = (b == 0) ? mOffColor : mOnColor;  // draw last pixel in row
                                mPixMap[q1 + dx] = (b == 0) ? mOffColor : mOnColor;  // draw last pixel in row
                                q += COLS * PIXELS_PER_COL * 2;                     //  advance q
                                q1 += COLS * PIXELS_PER_COL * 2;                     //  advance q1
                            }
                            mBitmapDirty = true;
                        }
                    }
                }


                public void MoveChar(Int32 x1, Int32 y1, Int32 x2, Int32 y2)
                { // move (copy) a character bit map from one char location to another
                    // x1y1 target x2y2 source

                    x1 *= PIXELS_PER_COL;
                    y1 *= PIXELS_PER_ROW;
                    Int32 q1 = y1 * COLS * PIXELS_PER_COL + x1;
                    x2 *= PIXELS_PER_COL;
                    y2 *= PIXELS_PER_ROW;
                    Int32 q2 = y2 * COLS * PIXELS_PER_COL + x2;
                    {
                        for (Int32 dy = 0; dy < PIXELS_PER_ROW; dy++)
                        {   // 20 lines
                            for (Int32 dx = 0; dx < PIXELS_PER_COL; dx++)
                            {
                                mPixMap[q1 + dx] = mPixMap[q2 + dx];
                            }
                            q1 += COLS * PIXELS_PER_COL;
                            q2 += COLS * PIXELS_PER_COL;
                        }
                    }
                }
                public void BlankChar(Int32 x1, Int32 y1)
                { // move (copy) a character bit map from one char location to another
                    // x1y1 target

                    x1 *= PIXELS_PER_COL;
                    y1 *= PIXELS_PER_ROW;
                    Int32 q1 = y1 * COLS * PIXELS_PER_COL + x1;
                    {
                        for (Int32 dy = 0; dy < PIXELS_PER_ROW; dy++)
                        {   // 20 lines
                            for (Int32 dx = 0; dx < PIXELS_PER_COL; dx++)
                            {
                                mPixMap[q1 + dx] = 0;
                            }
                            q1 += COLS * PIXELS_PER_COL;
                        }
                    }
                }



                public void MoveCursorRel(Int32 dx, Int32 dy)
                {
                    Int32 x = mX + dx;
                    if (x < 0) x = 0; else if (x >= COLS) x = COLS - 1;
                    Int32 y = mY + dy;
                    if (y < 0) y = 0; else if (y >= ROWS) y = ROWS - 1;

                    if (((x != mX) || (y != mY)))
                    {                   
                        mX = x;
                        mY = y;
                    }
                }

                public void MoveCursorAbs(Int32 dx, Int32 dy)
                {
                    Int32 x = dx;
                    if (x < 0) x = 0; else if (x >= COLS) x = COLS - 1;
                    Int32 y = dy;
                    if (y < 0) y = 0; else if (y >= ROWS) y = ROWS - 1;
                    if (((x != mX) || (y != mY)))
                    {
                        mX = x;
                        mY = y;
                    }
                }

                public void move_cursor(int nx, int ny)
                {
                    if (nx >= Display.COLS) nx = Display.COLS - 1;
                    if (ny >= Display.ROWS) ny = CursorY;

                    MoveCursorAbs(nx, ny);
                    return;
                }

                public void ScrollUpY(Int32 ny1, Int32 ny2)  // used with ESC[M, this scrolls data up the screen from last line to cursor.
                {
                    if (scrollLock) return;
                    lock (Bitmap)
                    {
                        Int32 p, x, y;
                        for (y = ny1; y < ny2; y++)
                        {
                            for (x = 0; x < Display.COLS; x++)
                            {
                                MoveChar(x, y, x, y + 1);
                                p = x + Display.COLS * y;
                                mChars[p] = mChars[p + Display.COLS];
                            }
                        }
                        for (x = 0; x < Display.COLS; x++)
                        {
                            BlankChar(x, (Display.ROWS - 1 - lockLine));
                            p = x + Display.COLS * (Display.ROWS - 1 - lockLine);
                            mChars[p] = 32;
                        }
                        BitmapDirty = true;
                    }
                }

                public void ScrollDownY(Int32 ny1, Int32 ny2)  // moves the characters down the screen from cursor
                {
                    if (scrollLock) return;
                    lock (Bitmap)
                    {
                        Int32 p, x, y;
                        for (y = ny2; y > ny1; y--)
                        {
                            for (x = 0; x < Display.COLS; x++)
                            {
                                MoveChar(x, y, x, y - 1);
                                p = x + Display.COLS * y;
                                mChars[p] = mChars[p - Display.COLS];
                            }
                        }
                        for (x = 0; x < Display.COLS; x++)
                        {
                            BlankChar(x, ny1);
                            p = x + Display.COLS * ny1;
                            mChars[p] = 32;
                        }

                        BitmapDirty = true;
                    }
                }


                // this needs to be rewritten to preserve the desired tint even when brightening from zero
                public void ChangeBrightness(Int32 delta)
                {
                    mBrightness += delta;
                    if (mBrightness < 5) mBrightness = 5;
                    else if (mBrightness > 100) mBrightness = 100;
                    UInt32 old = mOnColor;
                    mOnColor = Color(mBrightness);
                    ReplacePixels(old, mOnColor);
                }

                public void Beep()
                {
                    SystemSounds.Beep.Play();
                }

                // P4 phosphor colors (CIE chromaticity coordinates: x=0.275 y=0.290)
                private UInt32 Color(Int32 brightness)
                {
                    if ((brightness < 0) || (brightness > 100)) throw new ArgumentOutOfRangeException("brightness");
                    UInt32 c;
                    switch (brightness)
                    {
                        case 100: c = 0xFFE6FFFF; break;
                        case 95: c = 0xFFDAF5FF; break;
                        case 90: c = 0xFFCFE8FF; break;
                        case 85: c = 0xFFC4DCFF; break;
                        case 80: c = 0xFFB8CFF1; break;
                        case 75: c = 0xFFADC2E2; break;
                        case 70: c = 0xFFA2B6D3; break;
                        case 65: c = 0xFF96A9C5; break;
                        case 60: c = 0xFF8A9CB6; break;
                        case 55: c = 0xFF7F8FA7; break;
                        case 50: c = 0xFF738298; break;
                        case 45: c = 0xFF677488; break;
                        case 40: c = 0xFF5B6779; break;
                        case 35: c = 0xFF4F5A69; break;
                        case 30: c = 0xFF434C5A; break;
                        case 25: c = 0xFF363E4A; break;
                        case 20: c = 0xFF2A3039; break;
                        case 15: c = 0xFF1D2229; break;
                        case 10: c = 0xFF0f1318; break;
                        case 5: c = 0xFF040506; break;
                        case 0: c = 0xFF000000; break;
                        default: c = 0; break;
                    }
                    if (mOptGreenFilter)
                    {
                        // green filter passes 100% green, 6.25% blue, 6.25% red
                        UInt32 b = (c & 0x000000FF) >> 4;
                        c >>= 8;
                        UInt32 g = (c & 0x000000FF);
                        c >>= 8;
                        UInt32 r = (c & 0x000000FF) >> 4;
                        c &= 0xFFFFFF00;
                        c |= r;
                        c <<= 8;
                        c |= g;
                        c <<= 8;
                        c |= b;
                    }
                    return c;
                }

                private void ReplacePixels(UInt32 oldColor, UInt32 newColor)
                {
                    if (oldColor == newColor) return;
                    lock (mBitmap)
                    {
                        for (Int32 i = 0; i < mPixMap.Length; i++) if (mPixMap[i] == oldColor) mPixMap[i] = newColor;
                    }
                }


                public void TurnOnCursor()
                {
                    if (cursorOff == false)
                    {
                        //mCursorTimer.Change(500, 250);
                        while (!mCursorTimer.Change(500, 250)) { }
                        mCursorVisible = false;
                    }

                }

                public void TurnOffCursor()
                {
                    //mCursorTimer.Change(-1, -1);
                    while ( !mCursorTimer.Change(-1, -1)) { }
                    clearCursor();
                }


                private void CursorTimer_Callback(Object state)
                {
                    //if ((cursorOff == false) && (maskCursor == false));
                    if (cursorOff == false)
                    {
                        ToggleCursor();
                    }
                }


                public void ToggleCursor()
                {
                    // draw the entire 9x20
                    // draw whatever character is under the cursor
                    if (cursorOff == false)
                    {
                        // read the pixel data and invert
                        lock (mBitmap)
                        {
                            Int32 x = mX * PIXELS_PER_COL;
                            Int32 y = mY * PIXELS_PER_ROW;
                            Int32 q = y * COLS * PIXELS_PER_COL + x;
                            for (Int32 dy = 0; dy < 20; dy++)                    // 10 pairs of lines
                            {
                                for (Int32 dx = 0; dx < 9; dx++)
                                {
                                    if (mPixMap[q + dx] == mOnColor)  // pixel is on, turn off
                                    {
                                        mPixMap[q + dx] = mOffColor;
                                    }
                                    else  // pixel is off, turn on
                                    {
                                        mPixMap[q + dx] = mOnColor;
                                    }
                                }
                                q += COLS * PIXELS_PER_COL;                     //  advance q
                            }
                            mBitmapDirty = true;
                        }
                        mCursorVisible = !mCursorVisible;       // signals status of cursor inversion
                    }
                }


                public void clearCursor()
                {
                    if(mCursorVisible)
                    {
                        cursorOff = false;
                        ToggleCursor();
                        cursorOff = true;
                    }
                    
                }



                // DVI Character Generator ROM
                // ROM size: 4Kb (2k used, 8*256) 
                // A2-A0 = char scan line 0..7 (8 scan lines per char)
                // A9-A3 = char number (ASCII code)
                // D6-D0 = char scan line pixels (MSB=first pixel)
                // ASCII codes below 32 not used for DVI
                static private readonly Byte[] CharGen = {

                    //M100 character set from DVI, 8x8 matrix, 00 to 255
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x08, 0x08, 0x08, 0x08, 0x00, 0x08, 0x00,
                    0x24, 0x24, 0x24, 0x00, 0x00, 0x00, 0x00, 0x00, 0x24, 0x24, 0x7E, 0x24, 0x7E, 0x24, 0x24, 0x00,
                    0x08, 0x3E, 0x48, 0x3C, 0x0A, 0x7C, 0x08, 0x00, 0x00, 0x62, 0x64, 0x08, 0x10, 0x26, 0x46, 0x00,
                    0x30, 0x48, 0x48, 0x30, 0x4A, 0x44, 0x3A, 0x00, 0x04, 0x08, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x04, 0x08, 0x10, 0x10, 0x10, 0x08, 0x04, 0x00, 0x20, 0x10, 0x08, 0x08, 0x08, 0x10, 0x20, 0x00,
                    0x08, 0x2A, 0x1C, 0x08, 0x1C, 0x2A, 0x08, 0x00, 0x00, 0x08, 0x08, 0x3E, 0x08, 0x08, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x08, 0x10, 0x00, 0x00, 0x00, 0x7E, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x00,
                    0x3C, 0x42, 0x46, 0x5A, 0x62, 0x42, 0x3C, 0x00, 0x08, 0x18, 0x28, 0x08, 0x08, 0x08, 0x3E, 0x00,
                    0x3C, 0x42, 0x02, 0x0C, 0x30, 0x40, 0x7E, 0x00, 0x3C, 0x42, 0x02, 0x1C, 0x02, 0x42, 0x3C, 0x00,
                    0x04, 0x0C, 0x14, 0x24, 0x7E, 0x04, 0x04, 0x00, 0x7E, 0x40, 0x78, 0x04, 0x02, 0x04, 0x78, 0x00,
                    0x1C, 0x20, 0x40, 0x7C, 0x42, 0x42, 0x3C, 0x00, 0x7E, 0x42, 0x04, 0x08, 0x10, 0x10, 0x10, 0x00,
                    0x3C, 0x42, 0x42, 0x3C, 0x42, 0x42, 0x3C, 0x00, 0x3C, 0x42, 0x42, 0x3E, 0x02, 0x04, 0x38, 0x00,
                    0x00, 0x00, 0x08, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x08, 0x08, 0x10,
                    0x06, 0x0C, 0x18, 0x30, 0x18, 0x0C, 0x06, 0x00, 0x00, 0x00, 0x7E, 0x00, 0x7E, 0x00, 0x00, 0x00,
                    0x60, 0x30, 0x18, 0x0C, 0x18, 0x30, 0x60, 0x00, 0x3C, 0x42, 0x02, 0x0C, 0x10, 0x00, 0x10, 0x00,
                    0x3C, 0x42, 0x02, 0x3A, 0x4A, 0x4A, 0x3C, 0x00, 0x18, 0x24, 0x42, 0x7E, 0x42, 0x42, 0x42, 0x00,
                    0x7C, 0x22, 0x22, 0x3C, 0x22, 0x22, 0x7C, 0x00, 0x1C, 0x22, 0x40, 0x40, 0x40, 0x22, 0x1C, 0x00,
                    0x78, 0x24, 0x22, 0x22, 0x22, 0x24, 0x78, 0x00, 0x7E, 0x40, 0x40, 0x78, 0x40, 0x40, 0x7E, 0x00,
                    0x7E, 0x40, 0x40, 0x78, 0x40, 0x40, 0x40, 0x00, 0x1C, 0x22, 0x40, 0x4E, 0x42, 0x22, 0x1C, 0x00,
                    0x42, 0x42, 0x42, 0x7E, 0x42, 0x42, 0x42, 0x00, 0x1C, 0x08, 0x08, 0x08, 0x08, 0x08, 0x1C, 0x00,
                    0x0E, 0x04, 0x04, 0x04, 0x04, 0x44, 0x38, 0x00, 0x42, 0x44, 0x48, 0x70, 0x48, 0x44, 0x42, 0x00,
                    0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x7E, 0x00, 0x42, 0x66, 0x5A, 0x5A, 0x42, 0x42, 0x42, 0x00,
                    0x42, 0x62, 0x52, 0x4A, 0x46, 0x42, 0x42, 0x00, 0x3C, 0x42, 0x42, 0x42, 0x42, 0x42, 0x3C, 0x00,
                    0x7C, 0x42, 0x42, 0x7C, 0x40, 0x40, 0x40, 0x00, 0x3C, 0x42, 0x42, 0x42, 0x4A, 0x44, 0x3A, 0x00,
                    0x7C, 0x42, 0x42, 0x7C, 0x48, 0x44, 0x42, 0x00, 0x3C, 0x42, 0x40, 0x3C, 0x02, 0x42, 0x3C, 0x00,
                    0x3E, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x00, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x3C, 0x00,
                    0x42, 0x42, 0x42, 0x24, 0x24, 0x18, 0x18, 0x00, 0x42, 0x42, 0x42, 0x5A, 0x5A, 0x66, 0x42, 0x00,
                    0x42, 0x42, 0x24, 0x18, 0x24, 0x42, 0x42, 0x00, 0x22, 0x22, 0x22, 0x1C, 0x08, 0x08, 0x08, 0x00,
                    0x7E, 0x02, 0x04, 0x18, 0x20, 0x40, 0x7E, 0x00, 0x3C, 0x20, 0x20, 0x20, 0x20, 0x20, 0x3C, 0x00,
                    0x00, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x00, 0x3C, 0x04, 0x04, 0x04, 0x04, 0x04, 0x3C, 0x00,
                    0x08, 0x14, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF,
                    0x10, 0x08, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x38, 0x04, 0x3C, 0x44, 0x3A, 0x00,
                    0x40, 0x40, 0x5C, 0x62, 0x42, 0x62, 0x5C, 0x00, 0x00, 0x00, 0x3C, 0x42, 0x40, 0x42, 0x3C, 0x00,
                    0x02, 0x02, 0x3A, 0x46, 0x42, 0x46, 0x3A, 0x00, 0x00, 0x00, 0x3C, 0x42, 0x7E, 0x40, 0x3C, 0x00,
                    0x0C, 0x12, 0x10, 0x7C, 0x10, 0x10, 0x10, 0x00, 0x00, 0x00, 0x3A, 0x46, 0x46, 0x3A, 0x02, 0x3C,
                    0x40, 0x40, 0x5C, 0x62, 0x42, 0x42, 0x42, 0x00, 0x08, 0x00, 0x18, 0x08, 0x08, 0x08, 0x1C, 0x00,
                    0x04, 0x00, 0x0C, 0x04, 0x04, 0x04, 0x44, 0x38, 0x40, 0x40, 0x44, 0x48, 0x50, 0x68, 0x44, 0x00,
                    0x18, 0x08, 0x08, 0x08, 0x08, 0x08, 0x1C, 0x00, 0x00, 0x00, 0x76, 0x49, 0x49, 0x49, 0x49, 0x00,
                    0x00, 0x00, 0x5C, 0x62, 0x42, 0x42, 0x42, 0x00, 0x00, 0x00, 0x3C, 0x42, 0x42, 0x42, 0x3C, 0x00,
                    0x00, 0x00, 0x5C, 0x62, 0x62, 0x5C, 0x40, 0x40, 0x00, 0x00, 0x3A, 0x46, 0x46, 0x3A, 0x02, 0x02,
                    0x00, 0x00, 0x5C, 0x62, 0x40, 0x40, 0x40, 0x00, 0x00, 0x00, 0x3E, 0x40, 0x3C, 0x02, 0x7C, 0x00,
                    0x10, 0x10, 0x7C, 0x10, 0x10, 0x12, 0x0C, 0x00, 0x00, 0x00, 0x44, 0x44, 0x44, 0x44, 0x3A, 0x00,
                    0x00, 0x00, 0x42, 0x42, 0x42, 0x24, 0x18, 0x00, 0x00, 0x00, 0x41, 0x49, 0x49, 0x49, 0x36, 0x00,
                    0x00, 0x00, 0x42, 0x24, 0x18, 0x24, 0x42, 0x00, 0x00, 0x00, 0x42, 0x42, 0x46, 0x3A, 0x02, 0x3C,
                    0x00, 0x00, 0x7E, 0x04, 0x18, 0x20, 0x7E, 0x00, 0x0C, 0x10, 0x10, 0x20, 0x10, 0x10, 0x0C, 0x00,
                    0x08, 0x08, 0x08, 0x00, 0x08, 0x08, 0x08, 0x00, 0x30, 0x08, 0x08, 0x04, 0x08, 0x08, 0x30, 0x00,
                    0x30, 0x49, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x3E, 0x63, 0x63, 0x1C, 0x22, 0x63, 0x7F, 0x00, 0x18, 0x3C, 0x7E, 0x46, 0x5A, 0x46, 0x5E, 0x7E,
                    0x70, 0x70, 0x4A, 0x44, 0x4A, 0x70, 0x70, 0x00, 0x3F, 0x21, 0x41, 0x67, 0x70, 0x78, 0x7C, 0x7E,
                    0x18, 0xDB, 0xFF, 0xDB, 0x18, 0xDB, 0xFF, 0xDB, 0x18, 0x18, 0xFF, 0xFF, 0x18, 0x18, 0x3C, 0x00,
                    0x08, 0x1C, 0x3E, 0x55, 0x7F, 0x55, 0x7F, 0x00, 0x7F, 0x3F, 0x7F, 0x41, 0x77, 0x77, 0x7F, 0x00,
                    0x08, 0x00, 0x08, 0x08, 0x08, 0x08, 0x08, 0x00, 0x0F, 0x08, 0x08, 0x08, 0x08, 0x28, 0x10, 0x00,
                    0x01, 0x02, 0x7F, 0x08, 0x7F, 0x20, 0x40, 0x00, 0x7F, 0x21, 0x10, 0x0C, 0x10, 0x21, 0x7F, 0x00,
                    0x00, 0x30, 0x49, 0x06, 0x30, 0x49, 0x06, 0x00, 0x08, 0x08, 0x3E, 0x08, 0x08, 0x00, 0x3E, 0x00,
                    0x04, 0x08, 0x08, 0x08, 0x08, 0x08, 0x10, 0x00, 0x04, 0x0C, 0x1C, 0x3C, 0x1C, 0x0C, 0x04, 0x00,
                    0x3C, 0x42, 0x81, 0x81, 0xFF, 0x24, 0x24, 0xE7, 0x3C, 0x42, 0x81, 0x81, 0xFF, 0x42, 0x42, 0x66,
                    0x1C, 0x2A, 0x08, 0x08, 0x08, 0x2A, 0x1C, 0x00, 0x08, 0x14, 0x1C, 0x08, 0x1C, 0x2A, 0x14, 0x22,
                    0x08, 0x14, 0x28, 0x3E, 0x08, 0x14, 0x22, 0x00, 0x1F, 0x03, 0x05, 0x79, 0x49, 0x48, 0x78, 0x00,
                    0x1C, 0x22, 0x22, 0x1C, 0x08, 0x3E, 0x08, 0x00, 0x61, 0x82, 0x84, 0x68, 0x16, 0x29, 0x49, 0x86,
                    0x1C, 0x2A, 0x08, 0x08, 0x08, 0x08, 0x08, 0x00, 0x08, 0x08, 0x08, 0x08, 0x08, 0x2A, 0x1C, 0x00,
                    0x00, 0x02, 0x01, 0x7F, 0x01, 0x02, 0x00, 0x00, 0x00, 0x20, 0x40, 0x7F, 0x40, 0x20, 0x00, 0x00,
                    0x3C, 0x66, 0xE7, 0x81, 0xE7, 0x18, 0x7E, 0x00, 0x08, 0x14, 0x22, 0x41, 0x22, 0x14, 0x08, 0x00,
                    0x00, 0x66, 0x99, 0x81, 0x81, 0x42, 0x24, 0x18, 0x1C, 0x22, 0x41, 0x55, 0x6B, 0x08, 0x08, 0x00,
                    0x04, 0x08, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x10, 0x38, 0x04, 0x3C, 0x44, 0x3A, 0x00,
                    0x00, 0x3C, 0x42, 0x40, 0x42, 0x3C, 0x10, 0x20, 0x08, 0x14, 0x10, 0x7C, 0x10, 0x12, 0x7C, 0x00,
                    0x10, 0x08, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x22, 0x22, 0x22, 0x3D, 0x20, 0x20, 0x40,
                    0x08, 0x14, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7F, 0x3E, 0x1C, 0x08, 0x00, 0x00,
                    0x08, 0x08, 0x1C, 0x08, 0x08, 0x08, 0x08, 0x00, 0x3C, 0x40, 0x3C, 0x42, 0x3C, 0x02, 0x3C, 0x00,
                    0x7F, 0x43, 0x5D, 0x43, 0x57, 0x59, 0x7F, 0x00, 0x7F, 0x63, 0x5D, 0x5F, 0x5D, 0x63, 0x7F, 0x00,
                    0x42, 0x44, 0x48, 0x50, 0x2A, 0x4E, 0x82, 0x00, 0xE0, 0x21, 0xC2, 0x24, 0xE8, 0x15, 0x27, 0x41,
                    0x42, 0x44, 0x48, 0x57, 0x21, 0x47, 0x84, 0x07, 0x3F, 0x4A, 0x4A, 0x3A, 0x0A, 0x0A, 0x0A, 0x00,
                    0x22, 0x14, 0x08, 0x3E, 0x08, 0x3E, 0x08, 0x00, 0x24, 0x00, 0x18, 0x24, 0x42, 0x7E, 0x42, 0x00,
                    0x24, 0x00, 0x3C, 0x42, 0x42, 0x42, 0x3C, 0x00, 0x24, 0x00, 0x42, 0x42, 0x42, 0x42, 0x3C, 0x00,
                    0x08, 0x1C, 0x2A, 0x28, 0x2A, 0x1C, 0x08, 0x00, 0x00, 0x00, 0x30, 0x49, 0x06, 0x00, 0x00, 0x00,
                    0x28, 0x00, 0x38, 0x04, 0x3C, 0x44, 0x3A, 0x00, 0x00, 0x24, 0x00, 0x3C, 0x42, 0x42, 0x3C, 0x00,
                    0x00, 0x28, 0x00, 0x44, 0x44, 0x44, 0x3A, 0x00, 0x3C, 0x22, 0x22, 0x3C, 0x22, 0x22, 0xFC, 0x00,
                    0x7F, 0x08, 0x08, 0x63, 0x55, 0x49, 0x49, 0x00, 0x08, 0x10, 0x3C, 0x42, 0x7E, 0x40, 0x3C, 0x00,
                    0x00, 0x20, 0x10, 0x44, 0x44, 0x44, 0x3A, 0x00, 0x10, 0x08, 0x3C, 0x42, 0x7E, 0x40, 0x3C, 0x00,
                    0x00, 0x28, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x12, 0x10, 0x38, 0x10, 0x10, 0x38, 0x00,
                    0x10, 0x28, 0x00, 0x38, 0x04, 0x3C, 0x44, 0x3A, 0x18, 0x24, 0x00, 0x3C, 0x42, 0x7E, 0x40, 0x3C,
                    0x00, 0x08, 0x14, 0x00, 0x08, 0x00, 0x08, 0x08, 0x18, 0x24, 0x00, 0x3C, 0x42, 0x42, 0x3C, 0x00,
                    0x10, 0x28, 0x00, 0x44, 0x44, 0x44, 0x3A, 0x00, 0x08, 0x14, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x24, 0x00, 0x3C, 0x42, 0x7E, 0x40, 0x3C, 0x00, 0x00, 0x00, 0x14, 0x00, 0x08, 0x00, 0x08, 0x08,
                    0x08, 0x10, 0x38, 0x04, 0x3C, 0x44, 0x3A, 0x00, 0x00, 0x04, 0x08, 0x00, 0x08, 0x00, 0x08, 0x08,
                    0x00, 0x08, 0x10, 0x3C, 0x42, 0x42, 0x3C, 0x00, 0x00, 0x08, 0x10, 0x44, 0x44, 0x44, 0x3A, 0x00,
                    0x08, 0x10, 0x42, 0x42, 0x46, 0x3A, 0x02, 0x3C, 0x32, 0x4C, 0x00, 0x5C, 0x62, 0x42, 0x42, 0x00,
                    0x32, 0x4C, 0x00, 0x38, 0x04, 0x3C, 0x44, 0x3A, 0x32, 0x4C, 0x00, 0x3C, 0x42, 0x42, 0x3C, 0x00,
                    0x18, 0x24, 0x00, 0x18, 0x24, 0x42, 0x7E, 0x42, 0x18, 0x24, 0x00, 0x7E, 0x40, 0x78, 0x40, 0x7E,
                    0x08, 0x14, 0x00, 0x1C, 0x08, 0x08, 0x08, 0x1C, 0x18, 0x24, 0x00, 0x3C, 0x42, 0x42, 0x42, 0x3C,
                    0x18, 0x24, 0x00, 0x42, 0x42, 0x42, 0x42, 0x3C, 0x14, 0x00, 0x1C, 0x08, 0x08, 0x08, 0x1C, 0x00,
                    0x24, 0x00, 0x7E, 0x40, 0x78, 0x40, 0x7E, 0x00, 0x08, 0x10, 0x7E, 0x40, 0x78, 0x40, 0x7E, 0x00,
                    0x08, 0x10, 0x00, 0x18, 0x24, 0x42, 0x7E, 0x42, 0x08, 0x10, 0x00, 0x38, 0x10, 0x10, 0x10, 0x38,
                    0x08, 0x10, 0x3C, 0x42, 0x42, 0x42, 0x3C, 0x00, 0x08, 0x10, 0x42, 0x42, 0x42, 0x42, 0x3C, 0x00,
                    0x04, 0x08, 0x22, 0x22, 0x1C, 0x08, 0x08, 0x08, 0x10, 0x08, 0x42, 0x42, 0x42, 0x42, 0x3C, 0x00,
                    0x10, 0x08, 0x7E, 0x40, 0x78, 0x40, 0x7E, 0x00, 0x10, 0x08, 0x00, 0x18, 0x24, 0x42, 0x7E, 0x42,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0xF0, 0xF0, 0xF0, 0x00, 0x00, 0x00, 0x00,
                    0x0F, 0x0F, 0x0F, 0x0F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0xF0, 0xF0, 0xF0,
                    0x00, 0x00, 0x00, 0x00, 0x0F, 0x0F, 0x0F, 0x0F, 0xF0, 0xF0, 0xF0, 0xF0, 0x0F, 0x0F, 0x0F, 0x0F,
                    0x0F, 0x0F, 0x0F, 0x0F, 0xF0, 0xF0, 0xF0, 0xF0, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0,
                    0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0xFF, 0xFF, 0xFF, 0xFF, 0xF0, 0xF0, 0xF0, 0xF0,
                    0xFF, 0xFF, 0xFF, 0xFF, 0x0F, 0x0F, 0x0F, 0x0F, 0xF0, 0xF0, 0xF0, 0xF0, 0xFF, 0xFF, 0xFF, 0xFF,
                    0x0F, 0x0F, 0x0F, 0x0F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                    0x00, 0x00, 0x00, 0x1F, 0x10, 0x10, 0x10, 0x10, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0xF0, 0x10, 0x10, 0x10, 0x10, 0x00, 0x00, 0x00, 0xFF, 0x10, 0x10, 0x10, 0x10,
                    0x10, 0x10, 0x10, 0x1F, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10,
                    0x10, 0x10, 0x10, 0x1F, 0x00, 0x00, 0x00, 0x00, 0x10, 0x10, 0x10, 0xF0, 0x00, 0x00, 0x00, 0x00,
                    0x10, 0x10, 0x10, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x10, 0x10, 0x10, 0xF0, 0x10, 0x10, 0x10, 0x10,
                    0x10, 0x10, 0x10, 0xFF, 0x10, 0x10, 0x10, 0x10, 0xFF, 0xFE, 0xFC, 0xF8, 0xF0, 0xE0, 0xC0, 0x80,
                    0x01, 0x03, 0x07, 0x0F, 0x1F, 0x3F, 0x7F, 0xFF, 0xFF, 0x7F, 0x3F, 0x1F, 0x0F, 0x07, 0x03, 0x01,
                    0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE, 0xFF, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55,
                };
            }
        }


        // Terminal-I/O Interface and UART Timing

        public partial class VT52
        {
            private UART mUART;                     // UART emulator
            private String mCaption;                // desired window title bar caption
            private volatile Boolean mCaptionDirty; // true if caption has changed

            // called by main UI thread via constructor
            private void InitIO()
            {
                mUART = new UART(this);
                mUART.IO = new IO.Loopback(null);
                mCaption = String.Concat(Program.Name, " - ", mUART.IO.ConnectionString);
                mCaptionDirty = true;
            }

            public override String Caption
            {
                get { return mCaption; }
            }

            public override Boolean CaptionDirty
            {
                get { return mCaptionDirty; }
                set { mCaptionDirty = value; }
            }

            public override void Shutdown()
            {
                mUART.IO.Close();
            }

            private void SetBreakState(Boolean asserted)
            {
                mUART.IO.SetBreak(asserted);
            }

            private void SetTransmitSpeed(Int32 baudRate)
            {
                mUART.SetTransmitSpeed(baudRate);
            }

            private void SetReceiveSpeed(Int32 baudRate)
            {
                mUART.SetReceiveSpeed(baudRate);
            }

            private void SetTransmitParity(System.IO.Ports.Parity parity)
            {
                mUART.SetTransmitParity(parity);
            }

            private void SetLocalEcho(Boolean enabled)
            {
                mUART.SetLocalEcho(enabled);
            }

            private void Send(Byte data)
            {
                mUART.Send(data);
            }

            private class UART
            {
                private VT52 mVT52;             // for calling parent methods
                private Queue<Byte> mSendQueue; // bytes waiting to be fully sent by UART
                private System.Threading.Timer mSendTimer;       // UART byte transmit timer
                private Boolean mSendBusy;      // UART is transmitting bits
                private Int32 mSendSpeed;       // UART transmit baud rate
                private Double mSendRate;       // UART byte transmit rate
                private Int32 mSendPeriod;      // time (ms) for UART to send one byte
                private DateTime mSendClock;    // UART transmit clock
                private Int32 mSendCount;       // bytes transmitted since clock
                private Queue<Byte> mRecvQueue; // bytes waiting to be fully received by UART
                private System.Threading.Timer mRecvTimer;       // UART byte receive timer
                private Boolean mRecvBusy;      // UART is receiving bits
                private Int32 mRecvSpeed;       // UART receive baud rate
                private Double mRecvRate;       // UART byte receive rate
                private Int32 mRecvPeriod;      // time (ms) for UART to receive one byte
                private DateTime mRecvClock;    // UART receive clock
                private Int32 mRecvCount;       // bytes received since clock
                private Boolean mRecvBreak;     // receive break state
                private System.IO.Ports.Parity mParity;
                private Boolean mLocalEcho;     // UART loopback
                private IO mIO;                 // I/O interface

                public UART(VT52 parent)
                {
                    mVT52 = parent;
                    mSendQueue = new Queue<Byte>();
                    mSendTimer = new System.Threading.Timer(SendTimer_Callback, this, Timeout.Infinite, Timeout.Infinite);
                    SetTransmitSpeed(9600);
                    mRecvQueue = new Queue<Byte>();
                    mRecvTimer = new System.Threading.Timer(RecvTimer_Callback, this, Timeout.Infinite, Timeout.Infinite);
                    SetReceiveSpeed(9600);
                    SetTransmitParity(System.IO.Ports.Parity.Space);
                }

                public IO IO
                {
                    get
                    {
                        return mIO;
                    }
                    set
                    {
                        if (mIO == value) return;
                        if (mIO != null) mIO.Close();
                        mIO = value;
                        if (mIO != null) mIO.IOEvent += IOEvent;
                    }
                }

                public Int32 TransmitSpeed
                {
                    get { return mSendSpeed; }
                    set { SetTransmitSpeed(value); }
                }

                public Int32 ReceiveSpeed
                {
                    get { return mRecvSpeed; }
                    set { SetReceiveSpeed(value); }
                }

                public void SetTransmitSpeed(Int32 baudRate)
                {
                    lock (mSendQueue)
                    {
                        switch (baudRate)
                        {
                            case 0:
                                mSendSpeed = 0;
                                break;
                            case 19200:
                                mSendSpeed = 19200;
                                mSendRate = 1920;
                                mSendPeriod = 1;
                                break;
                            case 9600:
                                mSendSpeed = 9600;
                                mSendRate = 960;
                                mSendPeriod = 1;
                                break;
                            case 4800:
                                mSendSpeed = 4800;
                                mSendRate = 480;
                                mSendPeriod = 2;
                                break;
                            case 2400:
                                mSendSpeed = 2400;
                                mSendRate = 240;
                                mSendPeriod = 4;
                                break;
                            case 1200:
                                mSendSpeed = 1200;
                                mSendRate = 120;
                                mSendPeriod = 8;
                                break;
                            case 600:
                                mSendSpeed = 600;
                                mSendRate = 60;
                                mSendPeriod = 16;
                                break;
                            case 300:
                                mSendSpeed = 300;
                                mSendRate = 30;
                                mSendPeriod = 33;
                                break;
                            case 150:
                                mSendSpeed = 150;
                                mSendRate = 15;
                                mSendPeriod = 66;
                                break;
                            case 110:
                                mSendSpeed = 110;
                                mSendRate = 10;
                                mSendPeriod = 100;
                                break;
                            case 75:
                                mSendSpeed = 75;
                                mSendRate = 7.5;
                                mSendPeriod = 133;
                                break;
                            default:
                                throw new ArgumentException("baudRate");
                        }
                        if (mSendBusy)
                        {
                            mSendClock = DateTime.UtcNow;
                            mSendCount = 0;
                        }
                    }
                }

                public void SetReceiveSpeed(Int32 baudRate)
                {
                    lock (mRecvQueue)
                    {
                        switch (baudRate)
                        {
                            case 0:
                                mRecvSpeed = 0;
                                break;
                            case 19200:
                                mRecvSpeed = 19200;
                                mRecvRate = 1920;
                                mRecvPeriod = 1;
                                break;
                            case 9600:
                                mRecvSpeed = 9600;
                                mRecvRate = 960;
                                mRecvPeriod = 1;
                                break;
                            case 4800:
                                mRecvSpeed = 4800;
                                mRecvRate = 480;
                                mRecvPeriod = 2;
                                break;
                            case 2400:
                                mRecvSpeed = 2400;
                                mRecvRate = 240;
                                mRecvPeriod = 4;
                                break;
                            case 1200:
                                mRecvSpeed = 1200;
                                mRecvRate = 120;
                                mRecvPeriod = 8;
                                break;
                            case 600:
                                mRecvSpeed = 600;
                                mRecvRate = 60;
                                mRecvPeriod = 16;
                                break;
                            case 300:
                                mRecvSpeed = 300;
                                mRecvRate = 30;
                                mRecvPeriod = 33;
                                break;
                            case 150:
                                mRecvSpeed = 150;
                                mRecvRate = 15;
                                mRecvPeriod = 66;
                                break;
                            case 110:
                                mRecvSpeed = 110;
                                mRecvRate = 10;
                                mRecvPeriod = 100;
                                break;
                            case 75:
                                mRecvSpeed = 75;
                                mRecvRate = 7.5;
                                mRecvPeriod = 133;
                                break;
                            default:
                                throw new ArgumentException("baudRate");
                        }
                        if (mRecvBusy)
                        {
                            mRecvClock = DateTime.UtcNow;
                            mRecvCount = 0;
                        }
                    }
                }

                public void SetTransmitParity(System.IO.Ports.Parity parity)
                {
                    mParity = parity;
                }

                public void SetLocalEcho(Boolean enabled)
                {
                    mLocalEcho = enabled;
                }

                private Int32 NybbleParity(Int32 data)
                {
                    switch (data & 0x0F)
                    {
                        case 0x00: return 0;
                        case 0x01: return 1;
                        case 0x02: return 1;
                        case 0x03: return 0;
                        case 0x04: return 1;
                        case 0x05: return 0;
                        case 0x06: return 0;
                        case 0x07: return 1;
                        case 0x08: return 1;
                        case 0x09: return 0;
                        case 0x0A: return 0;
                        case 0x0B: return 1;
                        case 0x0C: return 0;
                        case 0x0D: return 1;
                        case 0x0E: return 1;
                        case 0x0F: return 0;
                        default: throw new ArgumentOutOfRangeException();
                    }
                }

                public void Send(Byte data)
                {
                    switch (mParity)
                    {
                        case System.IO.Ports.Parity.None:
                        case System.IO.Ports.Parity.Space:
                            break;

                        case System.IO.Ports.Parity.Mark:
                            data |= 0x80;
                            break;

                        case System.IO.Ports.Parity.Odd:
                            if ((NybbleParity(data >> 4) + NybbleParity(data)) != 1) data |= 0x80;
                            break;

                        case System.IO.Ports.Parity.Even:
                            if ((NybbleParity(data >> 4) + NybbleParity(data)) == 1) data |= 0x80;
                            break;
                    }

                    lock (mSendQueue)
                    {
                        if (mSendSpeed == 0)
                        {
                            mIO.Send(data);
                            return;
                        }
                        if ((!mSendBusy) && (!mIO.DelaySend)) mIO.Send(data);
                        else mSendQueue.Enqueue(data);
                        if (mLocalEcho && !(mIO is IO.Loopback)) IOEvent(this, new IOEventArgs(IOEventType.Data, data));
                        if (!mSendBusy)
                        {
                            mSendBusy = true;
                            mSendClock = DateTime.UtcNow;
                            mSendCount = 0;
                            mSendTimer.Change(0, mSendPeriod);
                        }
                    }
                }

                private void IOEvent(Object sender, IOEventArgs e)
                {
                    Debug.WriteLine("IOEvent: {0} {1} (0x{2:X2})", e.Type, (Char)e.Value, e.Value);
                    switch (e.Type)
                    {
                        case IOEventType.Data:
                            Byte data = (Byte)(e.Value & 0xFF); // full 8 bit
                            lock (mRecvQueue)
                            {
                                if (mRecvSpeed == 0)
                                {
                                    mVT52.Recv(data);
                                    return;
                                }
                                if ((!mRecvBusy) && (!mIO.DelayRecv)) mVT52.Recv(data);
                                else mRecvQueue.Enqueue(data);
                                if (!mRecvBusy)
                                {
                                    mRecvBusy = true;
                                    mRecvClock = DateTime.UtcNow;
                                    mRecvCount = 0;
                                    mRecvTimer.Change(0, mRecvPeriod);
                                }
                            }
                            break;
                        case IOEventType.Break:
                            lock (mRecvQueue) mRecvBreak = (e.Value != 0);
                            break;
                        case IOEventType.Flush:
                            lock (mRecvQueue) mRecvQueue.Clear();
                            break;
                        case IOEventType.Disconnect:
                            lock (mRecvQueue) mRecvQueue.Clear();
                            IO = new IO.Loopback(null);
                            mVT52.mCaption = String.Concat(Program.Name, " - ", IO.ConnectionString);
                            mVT52.mCaptionDirty = true;
                            break;
                    }
                }

                private void SendTimer_Callback(Object state)
                {
                    lock (mSendQueue)
                    {
                        TimeSpan t = DateTime.UtcNow.Subtract(mSendClock);
                        Int32 due = (Int32)(t.TotalSeconds * mSendRate + 0.5) - mSendCount;
                        Debug.WriteLine("SendTimer_Callback: due={0:D0} ct={1:D0}", due, mSendQueue.Count);
                        if (due <= 0) return;
                        while ((due-- > 0) && (mSendQueue.Count != 0))
                        {
                            mSendCount++;
                            mIO.Send(mSendQueue.Dequeue());
                        }
                        if (mSendQueue.Count == 0)
                        {
                            mSendTimer.Change(Timeout.Infinite, Timeout.Infinite);
                            mSendBusy = false;
                        }
                        else if (t.Minutes != 0)
                        {
                            mSendClock = DateTime.UtcNow;
                            mSendCount = 0;
                        }
                    }
                }

                private void RecvTimer_Callback(Object state)
                {
                    lock (mRecvQueue)
                    {
                        TimeSpan t = DateTime.UtcNow.Subtract(mRecvClock);
                        Int32 due = (Int32)(t.TotalSeconds * mRecvRate + 0.5) - mRecvCount;
                        Debug.WriteLine("RecvTimer_Callback: due={0:D0} ct={1:D0}", due, mRecvQueue.Count);
                        if (due <= 0) return;
                        while ((due-- > 0) && (mRecvQueue.Count != 0))
                        {
                            mRecvCount++;
                            mVT52.Recv(mRecvQueue.Dequeue());
                        }
                        if (mRecvQueue.Count == 0)
                        {
                            mRecvTimer.Change(Timeout.Infinite, Timeout.Infinite);
                            mRecvBusy = false;
                        }
                        else if (t.Minutes != 0)
                        {
                            mRecvClock = DateTime.UtcNow;
                            mRecvCount = 0;
                        }
                    }
                }
            }
        }
    }
}
