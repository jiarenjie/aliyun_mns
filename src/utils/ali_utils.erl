%%%-------------------------------------------------------------------
%%% @author jiarj
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 十一月 2017 13:45
%%%-------------------------------------------------------------------
-module(ali_utils).
-author("jiarj").
-compile(export_all).

-define(DELIMIT,<<$,>>).
%% API

%%msg => [{<<"15556430332">>,[{customer,<<"jiarenjie">>}]}] to map
msg_convent(List) ->
  [Type,Num, Map] = case length(List) of
                 1 ->
%%      todo singleContent
                   [Msg] = List,
                   convert_single(Msg);
                 _ ->
%%      todo multiContent
                   convert_multi(List, [<<"">>, #{}])
               end,
  [Type,Num,jsx:encode(Map)].

convert_multi([], [NumAcc,MapAcc]) ->
  << $, , Rest/binary>> = NumAcc,
  [<<"multiContent">>,Rest,MapAcc];
convert_multi([Msg | Rest], [NumAcc, MapAcc]) ->
%%  Keys = template_key(),
%%  PvMap = maps:from_list(lists:zip(Keys,Vals)),
  [_ , Num, PvMap] = convert_single(Msg),
  NewMapAcc = maps:put(binary_to_atom(Num, utf8), PvMap, MapAcc),
  NewNumAcc = <<NumAcc/binary, ?DELIMIT/binary, Num/binary>>,
  convert_multi(Rest, [NewNumAcc, NewMapAcc]).

convert_single({Num, PV}) ->
  NumAtom = convent_to_binary(Num),
  PvMap = maps:from_list(PV),
  [<<"singleContent">>,NumAtom, PvMap].

convent_to_binary(Num) when is_list(Num) ->
  erlang:list_to_binary(Num);
convent_to_binary(Num) when is_atom(Num) ->
  erlang:atom_to_binary(Num, utf8);
convent_to_binary(Num) when is_binary(Num) ->
  Num.

convent_to_string(Num) when is_list(Num) ->
  Num;
convent_to_string(Num) when is_atom(Num) ->
  erlang:atom_to_list(Num);
convent_to_string(Num) when is_binary(Num) ->
  erlang:binary_to_list(Num).

get_uuid()->
  UUID = list_to_binary(os:cmd("uuidgen")),
  remove_tail_char(UUID,1)
.

remove_tail_char(Bin,Bit) when is_integer(Bit),is_binary(Bin) ->
  Len = byte_size(Bin),
  Len1 = Len - Bit,
  <<Bin1:Len1/binary, _Tail:Bit/binary>> = Bin,
  Bin1.

now_gtm() ->
%%  {{Year, Month, Day}, {Hour, Minute, Second}} = calendar:now_to_local_time(erlang:now()),
  {{Year, Month, Day}, {Hour, Minute, Second}} = calendar:universal_time(),
  Week = calendar:day_of_the_week({Year, Month, Day}),
  WeekList = day(Week),
  MonthList = month_to_list(Month),
  String = lists:flatten(
    io_lib:format("~s, ~2..0w ~s ~4..0w ~2..0w:~2..0w:~2..0w GMT",
      [WeekList, Day, MonthList, Year, Hour, Minute, Second])),
  convent_to_binary(String).

now_utc() ->
  {MegaSecs, Secs, MicroSecs} = erlang:now(),
  {{Year, Month, Day}, {Hour, Minute, Second}} =
    calendar:now_to_universal_time({MegaSecs, Secs, MicroSecs}),
  lists:flatten(
    io_lib:format("~4..0w-~2..0w-~2..0wT~2..0w:~2..0w:~2..0wZ",
      [Year, Month, Day, Hour, Minute, Second])).

day(1) -> "Mon";
day(2) -> "Tue";
day(3) -> "Wed";
day(4) -> "Thu";
day(5) -> "Fri";
day(6) -> "Sat";
day(7) -> "Sun".

month_to_list(1) -> "Jan";
month_to_list(2) -> "Feb";
month_to_list(3) -> "Mar";
month_to_list(4) -> "Apr";
month_to_list(5) -> "May";
month_to_list(6) -> "Jun";
month_to_list(7) -> "Jul";
month_to_list(8) -> "Aug";
month_to_list(9) -> "Sep";
month_to_list(10) -> "Oct";
month_to_list(11) -> "Nov";
month_to_list(12) -> "Dec".

list_to_month("Jan") -> 1;
list_to_month("Feb") -> 2;
list_to_month("Mar") -> 3;
list_to_month("Apr") -> 4;
list_to_month("May") -> 5;
list_to_month("Jun") -> 6;
list_to_month("Jul") -> 7;
list_to_month("Aug") -> 8;
list_to_month("Sep") -> 9;
list_to_month("Oct") -> 10;
list_to_month("Nov") -> 11;
list_to_month("Dec") -> 12.