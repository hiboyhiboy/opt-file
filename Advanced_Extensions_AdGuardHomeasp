<!DOCTYPE html>
<!--app17_ver=2021-3-7=-->
<html>
<head>
<title><#Web_Title#> - AdGuardHome</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">

<link rel="shortcut icon" href="images/favicon.ico">
<link rel="icon" href="images/favicon.png">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/main.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/engage.itoggle.css">

<script type="text/javascript" src="/jquery.js"></script>
<script type="text/javascript" src="/bootstrap/js/bootstrap.min.js"></script>
<script type="text/javascript" src="/bootstrap/js/engage.itoggle.min.js"></script>
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/itoggle.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script>
var $j = jQuery.noConflict();

$j(document).ready(function() {

    init_itoggle('app_84',change_AdGuardHome_enable);
    init_itoggle('app_132',change_AdGuardHome_dns);
    document.form.app_86.value = '1';

});

</script>
<script>

<% login_state_hook(); %>

function initial(){
    show_banner(1);
    show_menu(8,<% nvram_get_x("", "AdGuardHome_L2"); %>,<% nvram_get_x("", "AdGuardHome_L3"); %>);
    show_footer();
    change_AdGuardHome_enable(1);
    change_AdGuardHome_dns(1);
	if (!login_safe())
		textarea_scripts_enabled(0);

}

function textarea_scripts_enabled(v){
	inputCtrl(document.form['scripts.app_19.sh'], v);
}

function applyRule(){
//    if(validForm()){
        showLoading();
        
        document.form.action_mode.value = " Apply ";
        document.form.current_page.value = "/Advanced_Extensions_app17.asp";
        document.form.next_page.value = "";
        
        document.form.submit();
//    }
}

function done_validating(action){
    refreshpage();
}

function change_AdGuardHome_enable(mflag){
	var m = document.form.app_84.value;
	var is_AdGuardHome_enable = (m == "1") ? "重启" : "更新";
	document.form.updateAdGuardHome.value = is_AdGuardHome_enable;
}
function change_AdGuardHome_dns(mflag){
	var m = document.form.app_132.value;
	var m = (m == "1") ? "0" : "1";
	showhide_div("AdGuardHome_85_tr", m);
}
function button_updateAdGuardHome(){
    change_AdGuardHome_enable(1);
	var $j = jQuery.noConflict();
	$j.post('/apply.cgi',
	{
		'action_mode': ' updateapp17 ',
	});
}

function button_AdGuardHome_wan_port(){
		var port = '3000';
		var porturl ='http://' + window.location.hostname + ":" + port;
		//alert(porturl);
		window.open(porturl,'AdGuardHome_wan_port');
}

</script>
</head>

<body onload="initial();" onunLoad="return unload_body();">

<div class="wrapper">
    <div class="container-fluid" style="padding-right: 0px">
        <div class="row-fluid">
            <div class="span3"><center><div id="logo"></div></center></div>
            <div class="span9" >
                <div id="TopBanner"></div>
            </div>
        </div>
    </div>

    <div id="Loading" class="popup_bg"></div>

    <iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>

    <form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">

    <input type="hidden" name="current_page" value="Advanced_Extensions_app17.asp">
    <input type="hidden" name="next_page" value="">
    <input type="hidden" name="next_host" value="">
    <input type="hidden" name="sid_list" value="APP;LANHostConfig;General;">
    <input type="hidden" name="group_id" value="">
    <input type="hidden" name="action_mode" value="">
    <input type="hidden" name="action_script" value="">
    <input type="hidden" name="wan_ipaddr" value="<% nvram_get_x("", "wan0_ipaddr"); %>" readonly="1">
    <input type="hidden" name="wan_netmask" value="<% nvram_get_x("", "wan0_netmask"); %>" readonly="1">
    <input type="hidden" name="dhcp_start" value="<% nvram_get_x("", "dhcp_start"); %>">
    <input type="hidden" name="dhcp_end" value="<% nvram_get_x("", "dhcp_end"); %>">
    <input type="hidden" name="app_86" value="<% nvram_get_x("", "app_86"); %>">

    <div class="container-fluid">
        <div class="row-fluid">
            <div class="span3">
                <!--Sidebar content-->
                <!--=====Beginning of Main Menu=====-->
                <div class="well sidebar-nav side_nav" style="padding: 0px;">
                    <ul id="mainMenu" class="clearfix"></ul>
                    <ul class="clearfix">
                        <li>
                            <div id="subMenu" class="accordion"></div>
                        </li>
                    </ul>
                </div>
            </div>

            <div class="span9">
                <!--Body content-->
                <div class="row-fluid">
                    <div class="span12">
                        <div class="box well grad_colour_dark_blue">
                            <h2 class="box_head round_top">AdGuardHome</h2>
                            <div class="round_bottom">
                                <div class="row-fluid">
                                    <div id="tabMenu" class="submenuBlock"></div>
                                    <div class="alert alert-info" style="margin: 10px;">欢迎使用 AdGuardHome ，这是一款全网广告拦截与反跟踪软件。在您将其安装完毕后，它将保护您所有家用设备，同时您不再需要安装任何客户端软件。随着物联网与连接设备的兴起，掌控您自己的整个网络环境变得越来越重要。<a href="https://adguard.com/zh_cn/adguard-home/overview.html" target="blank">AdGuard 主页</a>
                                    <div>项目地址：<a href="https://github.com/AdguardTeam/AdGuardHome" target="blank">https://github.com/AdguardTeam/AdGuardHome</a></div>
                                    <div>备注：①安装需要 30M+ 的空间 ②<a href="https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration#reset-web-password" target="blank">建议重置网页密码</a></div>
                                    <div>当前 app 文件:【<% nvram_get_x("", "app17_ver"); %>】，最新 app 文件:【<% nvram_get_x("", "app17_ver_n"); %>】 </div>
                                    <span style="color:#FF0000;" class=""></span></div>

                                    <table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
                                        <tr>
                                            <th colspan="4" style="background-color: #E3E3E3;">开关</th>
                                        </tr>
                                        <tr id="AdGuardHome_enable_tr" >
                                            <th width="30%">AdGuardHome 开关</th>
                                            <td>
                                                    <div class="main_itoggle">
                                                    <div id="app_84_on_of">
                                                        <input type="checkbox" id="app_84_fake" <% nvram_match_x("", "app_84", "1", "value=1 checked"); %><% nvram_match_x("", "app_84", "0", "value=0"); %>  />
                                                    </div>
                                                </div>
                                                <div style="position: absolute; margin-left: -10000px;">
                                                    <input type="radio" value="1" name="app_84" id="app_84_1" class="input" value="1" onClick="change_AdGuardHome_enable(1);" <% nvram_match_x("", "app_84", "1", "checked"); %> /><#checkbox_Yes#>
                                                    <input type="radio" value="0" name="app_84" id="app_84_0" class="input" value="0" onClick="change_AdGuardHome_enable(1);" <% nvram_match_x("", "app_84", "0", "checked"); %> /><#checkbox_No#>
                                                </div>
                                            </td>
                                            <td colspan="1">
                                                <input class="btn btn-success" type="button" name="updateAdGuardHome" value="更新" onclick="button_updateAdGuardHome()" />
                                            </td>
                                            <td colspan="1">
                                                <span style="color:#888;">版本：<% nvram_get_x("","AdGuardHome_v"); %></span>
                                            </td>
                                        </tr>
                                        <tr id="AdGuardHome_dns_tr" >
                                            <th style="border-top: 0 none;">成为默认 DNS 服务<div><span style="color:#888;">代替 dnsmasq 侦听 53 端口</span></div></th>
                                            <td style="border-top: 0 none;">
                                                    <div class="main_itoggle">
                                                    <div id="app_132_on_of">
                                                        <input type="checkbox" id="app_132_fake" <% nvram_match_x("", "app_132", "1", "value=1 checked"); %><% nvram_match_x("", "app_132", "0", "value=0"); %>  />
                                                    </div>
                                                </div>
                                                <div style="position: absolute; margin-left: -10000px;">
                                                    <input type="radio" value="1" name="app_132" id="app_132_1" class="input" value="1" onClick="change_AdGuardHome_dns(1);" <% nvram_match_x("", "app_132", "1", "checked"); %> /><#checkbox_Yes#>
                                                    <input type="radio" value="0" name="app_132" id="app_132_0" class="input" value="0" onClick="change_AdGuardHome_dns(1);" <% nvram_match_x("", "app_132", "0", "checked"); %> /><#checkbox_No#>
                                                </div>
                                            </td>
											<td colspan="2" style="border-top: 0 none;">
												<input class="btn btn-success" style="" type="button" value="Web管理界面" onclick="button_AdGuardHome_wan_port()" tabindex="24">
											</td>
                                        </tr>
										<tr id="AdGuardHome_85_tr" >
											<th style="border-top: 0 none;">外置 AdGuardHome 服务器:<div>（外部性能更好的机器）</div></th>
											<td colspan="3" style="border-top: 0 none;">
											<div class="input-append">
												<input maxlength="512" class="input" size="15" name="app_85" id="app_85" style="width: 175px;" placeholder="[空]"  value="<% nvram_get_x("","app_85"); %>" onKeyPress="return is_string(this,event);"/>
												<div><span style="color:#888;">默认[空]，填写外置服务地址，本机不启动程序。例： 192.168.123.123:5353</span></div>
											</div>
											</td>
										</tr>
										<tr>
											<th colspan="4" style="background-color: #E3E3E3;" >配置</th>
										</tr>
										<tr>
											<td colspan="4" style="border-top: 0 none;">
												<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('app_19_script')"><span>点这里自定义 AdGuardHome 配置</span></a>
												<div id="app_19_script">
													<textarea rows="6" wrap="off" spellcheck="false" maxlength="18192" class="span12" name="scripts.app_19.sh" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("scripts.app_19.sh",""); %></textarea>
												</div>
											</td>
										</tr>
                                        <tr>
                                            <td colspan="4" style="border-top: 0 none;">
                                                <br />
                                                <center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
                                            </td>
                                        </tr>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    </form>

    <div id="footer"></div>
</div>
</body>
</html>

