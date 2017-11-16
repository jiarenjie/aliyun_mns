%%%-------------------------------------------------------------------
%% @doc aliyun_sms public API
%% @end
%%%-------------------------------------------------------------------

-module(aliyun_mns).
-include_lib("xmerl/include/xmerl.hrl").

-behaviour(application).
%% Application callbacks
-export([start/2, stop/1]).
%% api
-export([send_msg/1, send_msg_sms/1]).


%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
  aliyun_mns_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
  ok.



send_msg(#{templateCode := _TemplateCode, msg := _Msg, signName := _SignName} = Req) when is_map(Req) ->
  #{
    url := Url
    , date := Date
    , contentType := Type
    , xmlversion := XmlVersion
    , authorization := Authorization
    , directSMS := DirectSMS
  } = gs_aliyun_mns:process(Req),

  Header = [
    {"Date",ali_utils:convent_to_string(Date)}
    ,{"Authorization",ali_utils:convent_to_string(Authorization)}
    ,{"x-mns-version" , ali_utils:convent_to_string(XmlVersion)}
  ],
%%  todo template to get xml
  Vals = [
    {directSMS,DirectSMS}
  ],
  {ok,Body} = ali_msg_dtl:render(Vals),
%%  send http post
  lager:info("Url:~p",[Url]),
  lager:info("Header:~p",[Header]),
  lager:info("Type:~p",[Type]),
  lager:info("DirectSMS:~ts",[DirectSMS]),
  lager:info("Body:~ts",[Body]),
  {ok,{_,_,Body2}} = http_utils:http_post(Url,Header,Type,Body),
%%  解析response xml
  {XmlElt, _} = xmerl_scan:string(Body2),
try
  [#xmlText{value = MessageBodyMD5 }] = xmerl_xpath:string("/Message/MessageBodyMD5/text()", XmlElt),
  lager:info("MessageBodyMD5:~p",[MessageBodyMD5]),
  [#xmlText{value = MessageId }] = xmerl_xpath:string("/Message/MessageId/text()", XmlElt),
  lager:info("MessageId:~p",[MessageId]),
  {ok,MessageId,MessageBodyMD5}
catch
    _:_  ->
      [#xmlText{value = Code }] = xmerl_xpath:string("/Error/Code/text()", XmlElt),
      lager:error("Code:~p",[Code]),
      [#xmlText{value = Message }] = xmerl_xpath:string("/Error/Message/text()", XmlElt),
      lager:error("Message:~p",[Message]),
      {error,Code,Message}
end.

send_msg_sms(#{templateCode := _TemplateCode, templateParam := _templateParam, signName := _SignName,phoneNumbers:= _PhoneNumbers} = Req)->
  Url = gs_aliyun_sms:process(Req),
  {ok,{_,_,Body}} = http_utils:http_get(binary_to_list(Url)),
  {XmlElt, _} = xmerl_scan:string(Body),

  try
  [#xmlText{value = RequestId }] = xmerl_xpath:string("/SendSmsResponse/RequestId/text()", XmlElt),
  [#xmlText{value = BizId }] = xmerl_xpath:string("/SendSmsResponse/BizId/text()", XmlElt),
  {ok,RequestId,BizId}
  catch
    _:_ ->
      [#xmlText{value = Code }] = xmerl_xpath:string("/Error/Code/text()", XmlElt),
      lager:error("Code:~p",[Code]),
      [#xmlText{value = RequestId2 }] = xmerl_xpath:string("/Error/RequestId/text()", XmlElt),
      lager:error("Message:~p",[RequestId2]),
      {error,RequestId2,Code}
  end.