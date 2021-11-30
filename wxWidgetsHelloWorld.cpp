// wxWidgets "Hello World" Program
// For compilers that support precompilation, includes "wx/wx.h".
#include <wx/wxprec.h>
#ifndef WX_PRECOMP
    #include <wx/wx.h>
#endif
/* now to indicate Unicode support. It can be explicitly set to 0 in setup.h under MSW or 
 * #define wxNO_IMPLICIT_WXSTRING_ENCODING 1
 * #define wxUSE_UNICODE 1 
 * #define wxUSE_UTF8_LOCALE_ONLY 1
 * #define wxUSE_UNICODE_UTF8 1
 * you can use –disable-unicode under Unix but doing this is strongly discouraged. 
 * By default, wxUSE_UNICODE_WCHAR is also defined as 1, however in UTF-8 build (described in the previous section), 
 * it is set to 0 and wxUSE_UNICODE_UTF8, which is usually 0, is set to 1 instead. 
 * In the latter case, wxUSE_UTF8_LOCALE_ONLY can also be set to 1 to indicate that all strings are considered to be in UTF-8.
 * 代码原文:  https://docs.wxwidgets.org/trunk/overview_helloworld.html
 * 编译本段代码：
 * $ c++ -o hello hello.cpp `wx-config --cxxflags --libs`
 */


class MyApp : public wxApp
{
public:
    virtual bool OnInit();
};
class MyFrame : public wxFrame
{
public:
    MyFrame();
private:
    void OnHello(wxCommandEvent& event);
    void OnExit(wxCommandEvent& event);
    void OnAbout(wxCommandEvent& event);
};
enum
{
    ID_Hello = 1
};
wxIMPLEMENT_APP(MyApp);
bool MyApp::OnInit()
{
    MyFrame *frame = new MyFrame();
    frame->Show(true);
    return true;
}
MyFrame::MyFrame()
    : wxFrame(NULL, wxID_ANY, _T("欢迎 Leisure Linux 的老铁们!"))
{
    wxMenu *menuFile = new wxMenu;
    menuFile->Append(ID_Hello, "&Hello...\tCtrl-H",
                     "Help in status bar for this menu item");
    menuFile->AppendSeparator();
    menuFile->Append(wxID_EXIT);
    wxMenu *menuHelp = new wxMenu;
    menuHelp->Append(wxID_ABOUT);
    wxMenuBar *menuBar = new wxMenuBar;
    menuBar->Append(menuFile, _T("&F文件"));
    menuBar->Append(menuHelp, _T("&H帮助"));
    SetMenuBar( menuBar );
    CreateStatusBar();
    SetStatusText(_T("让我们一起学习 wxWidgets!"));
    Bind(wxEVT_MENU, &MyFrame::OnHello, this, ID_Hello);
    Bind(wxEVT_MENU, &MyFrame::OnAbout, this, wxID_ABOUT);
    Bind(wxEVT_MENU, &MyFrame::OnExit, this, wxID_EXIT);
}
void MyFrame::OnExit(wxCommandEvent& event)
{
    Close(true);
}
void MyFrame::OnAbout(wxCommandEvent& event)
{
    wxMessageBox(_T("这是一个 wxWidgets 示例"),
                 _T("关于"), wxOK | wxICON_INFORMATION);
}
void MyFrame::OnHello(wxCommandEvent& event)
{
    wxLogMessage(_T("wxWidgets 的 Helloworld!"));
}
