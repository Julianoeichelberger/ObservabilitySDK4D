{
  *******************************************************************************

  Observability SDK for Delphi.

  Copyright (C) 2025 Juliano Eichelberger 

  License Notice:
  This software is licensed under the terms of the MIT License.

  As required by the license:
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
  The full license text can be found in the LICENSE file at the root of the project.

  For more details on the terms of use, please consult:
  https://opensource.org/licenses/MIT

  *******************************************************************************
}
unit Observability.Utils;

interface

type
  TTimestampEpoch = class
    class function Get(ADate: TDatetime): Int64;
  end;

implementation

Uses
  System.SysUtils, System.DateUtils;

{ TTimestampEpoch }

class function TTimestampEpoch.Get(ADate: TDatetime): Int64;
begin
  Result := StrToInt64(FormatFloat('0', DateTimeToUnix(ADate, False)) + FormatDateTime('zzz', ADate) + '000');
end;

end.
