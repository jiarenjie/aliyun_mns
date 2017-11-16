%%%-------------------------------------------------------------------
%%% @author jiarj
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 十一月 2017 10:46
%%%-------------------------------------------------------------------
-module(gs_aliyun_sms).
-author("jiarj").
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([start_link/0]).
-export([process/1]).
-define(SERVER, ?MODULE).
-record(state, {accessId, accessKey}).

-define(ACTION, 'SendSms').
-define(FORMAT, 'XML').
-define(REGIONID, <<"cn-hangzhou">>).
-define(SIGNATUREMETHOD, <<"HMAC-SHA1">>).
-define(SIGNATUREVERSION, <<"1.0">>).
-define(VERSION, <<"2017-05-25">>).
-define(HTTPMETHOD, get).
-define(URI, <<"http://dysmsapi.aliyuncs.com/">>).

%% API
%%====================================================================
%% Internal functions
%%====================================================================
start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
init([]) ->

  {ok, AccessId} = application:get_env(accessId),
  {ok, AccessKey} = application:get_env(accessKey),

  {ok, #state{accessId = AccessId
    , accessKey = AccessKey
  }}.

process(Map) when is_map(Map) ->
  gen_server:call(?SERVER, {process, Map}).

handle_call({process, #{
  templateCode := TemplateCode,
  templateParam := TemplateParam,
  signName := SignName,
  phoneNumbers := PhoneNumbers} = _Map}, _From, #state{accessId = AccessId, accessKey = AccessKey} = State) ->

  Req = #{
    accessKeyId => AccessId
    , action => ?ACTION
    , format => ?FORMAT
    , templateParam => TemplateParam
    , phoneNumbers => PhoneNumbers
    , regionId => ?REGIONID
    , signName => SignName
    , signatureMethod => ?SIGNATUREMETHOD
    , signatureNonce => ali_utils:get_uuid()
    , signatureVersion => ?SIGNATUREVERSION
    , templateCode => TemplateCode
    , timestamp => ali_utils:now_utc()
    , version => ?VERSION
    , httpMethod => ?HTTPMETHOD
    },
  SortQueryString = ali_sms_sign:sort_query_string(Req),
  lager:info("SortQueryString:~p",[SortQueryString]),
  Singature = ali_sms_sign:sign_url_encode(SortQueryString, ?HTTPMETHOD ,AccessKey),
  Url = <<?URI/binary ,"?Signature=" , Singature/binary ,"&" , SortQueryString/binary >> ,


  {reply, Url , State};
handle_call(_Request, _From, State) ->
  {noreply, State}.


handle_cast(_Request, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

get_signatureNonce() ->
  erlang:error(not_implemented).