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
unit Observability.Context;

interface

uses
  System.SysUtils, System.Generics.Collections,
  Observability.Interfaces;

type
  /// <summary>
  /// Implementation of observability context that maintains correlation information across distributed operations.
  /// This class stores trace correlation data (trace ID, span ID, parent span ID), service metadata,
  /// user information, and custom attributes/tags. It provides the foundation for distributed tracing
  /// by ensuring consistent correlation between spans, transactions, logs, and metrics.
  /// 
  /// Key Features:
  /// - Automatic ID generation using GUIDs
  /// - Parent-child relationship management
  /// - Service and user metadata storage
  /// - Custom tags and attributes support
  /// - Thread-safe cloning and inheritance
  /// - Factory methods for different creation scenarios
  /// </summary>
  TObservabilityContext = class(TInterfacedObject, IObservabilityContext)
  private
    FTraceId, FSpanId, FParentSpanId: string;
    FServiceName, FServiceVersion, FEnvironment: string;
    FUserId, FUserName, FUserEmail: string;
    FTags: TDictionary<string,string>;
    FAttributes: TDictionary<string,string>;
    
    /// <summary>
    /// Generates a unique identifier using GUID.
    /// Creates a 32-character hexadecimal string suitable for trace and span IDs.
    /// </summary>
    /// <returns>A unique identifier string</returns>
    function GenerateId: string;
  protected
    /// <summary>Gets the trace ID that identifies the entire distributed trace.</summary>
    function GetTraceId: string;
    /// <summary>Gets the span ID that identifies this specific operation within the trace.</summary>
    function GetSpanId: string;
    /// <summary>Gets the parent span ID for establishing parent-child relationships.</summary>
    function GetParentSpanId: string;
    /// <summary>Gets the service name for this application/service.</summary>
    function GetServiceName: string;
    /// <summary>Gets the service version for this application/service.</summary>
    function GetServiceVersion: string;
    /// <summary>Gets the deployment environment (development, staging, production, etc.).</summary>
    function GetEnvironment: string;
    /// <summary>Gets the user ID associated with this context.</summary>
    function GetUserId: string;
    /// <summary>Gets the username associated with this context.</summary>
    function GetUserName: string;
    /// <summary>Gets the user email associated with this context.</summary>
    function GetUserEmail: string;
    /// <summary>Gets the collection of tags for this context.</summary>
    function GetTags: TDictionary<string,string>;
    /// <summary>Gets the collection of attributes for this context.</summary>
    function GetAttributes: TDictionary<string,string>;
    /// <summary>Sets the trace ID for this context.</summary>
    procedure SetTraceId(const Value: string);
    /// <summary>Sets the span ID for this context.</summary>
    procedure SetSpanId(const Value: string);
    /// <summary>Sets the parent span ID for this context.</summary>
    procedure SetParentSpanId(const Value: string);
    /// <summary>Sets the service name for this context.</summary>
    procedure SetServiceName(const Value: string);
    /// <summary>Sets the service version for this context.</summary>
    procedure SetServiceVersion(const Value: string);
    /// <summary>Sets the deployment environment for this context.</summary>
    procedure SetEnvironment(const Value: string);
    /// <summary>Sets the user ID for this context.</summary>
    procedure SetUserId(const Value: string);
    /// <summary>Sets the username for this context.</summary>
    procedure SetUserName(const Value: string);
    /// <summary>Sets the user email for this context.</summary>
    procedure SetUserEmail(const Value: string);
    /// <summary>Adds or updates a tag in this context.</summary>
    procedure AddTag(const Key, Value: string);
    /// <summary>Adds or updates an attribute in this context.</summary>
    procedure AddAttribute(const Key, Value: string);
    /// <summary>Creates a deep copy of this context with a new span ID but same trace ID.</summary>
    function Clone: IObservabilityContext;
  public
    /// <summary>
    /// Creates a new observability context instance.
    /// Automatically generates new trace ID and span ID using GUIDs.
    /// Initializes empty collections for tags and attributes.
    /// </summary>
    constructor Create;
    
    /// <summary>
    /// Destroys the context instance and frees associated collections.
    /// Properly cleans up tags and attributes dictionaries.
    /// </summary>
    destructor Destroy; override;
    
    /// <summary>
    /// Factory method that creates a new context instance.
    /// Equivalent to calling Create constructor but returns interface.
    /// </summary>
    /// <returns>New context instance with generated IDs</returns>
    class function New: IObservabilityContext; static;
    
    /// <summary>
    /// Inline factory method for creating new contexts.
    /// Optimized version of New method for performance-critical scenarios.
    /// </summary>
    /// <returns>New context instance with generated IDs</returns>
    class function CreateNew: IObservabilityContext; static; inline;
    
    /// <summary>
    /// Creates a new context with a specific trace ID.
    /// Useful for continuing existing traces or implementing custom correlation.
    /// Generates a new span ID but uses the provided trace ID.
    /// </summary>
    /// <param name="TraceId">The trace ID to use for the new context</param>
    /// <returns>New context instance with the specified trace ID</returns>
    class function CreateWithTraceId(const TraceId: string): IObservabilityContext; static;
    
    /// <summary>
    /// Creates a child context from a parent context.
    /// Inherits trace ID, service metadata, user information, tags, and attributes from parent.
    /// Generates a new span ID and sets the parent's span ID as parent span ID.
    /// Used for creating child spans that maintain trace correlation.
    /// </summary>
    /// <param name="Parent">The parent context to inherit from</param>
    /// <returns>New child context with inherited properties</returns>
    class function CreateChild(const Parent: IObservabilityContext): IObservabilityContext; static;
  end;

implementation

{ TObservabilityContext }

/// <summary>
/// Creates a new observability context with automatically generated trace and span IDs.
/// Initializes the tags and attributes collections for storing custom metadata.
/// </summary>
constructor TObservabilityContext.Create;
begin
  inherited Create;
  FTags := TDictionary<string,string>.Create;
  FAttributes := TDictionary<string,string>.Create;
  FTraceId := GenerateId;
  FSpanId := GenerateId;
end;

/// <summary>
/// Destroys the context and properly frees the internal collections.
/// Ensures no memory leaks from tags and attributes dictionaries.
/// </summary>
destructor TObservabilityContext.Destroy;
begin
  FTags.Free;
  FAttributes.Free;
  inherited Destroy;
end;

/// <summary>
/// Factory method for creating new context instances.
/// Provides a clean interface-based creation pattern.
/// </summary>
class function TObservabilityContext.New: IObservabilityContext;
begin
  Result := TObservabilityContext.Create;
end;

class function TObservabilityContext.CreateNew: IObservabilityContext;
begin
  Result := New;
end;

/// <summary>
/// Creates a context with a specific trace ID for continuing existing traces.
/// Useful for distributed scenarios where trace ID is received from external sources.
/// </summary>
class function TObservabilityContext.CreateWithTraceId(const TraceId: string): IObservabilityContext;
var
  Context: TObservabilityContext;
begin
  Context := TObservabilityContext.Create;
  Context.FTraceId := TraceId;
  Result := Context;
end;

/// <summary>
/// Creates a child context that inherits all properties from the parent.
/// Essential for maintaining trace correlation in parent-child span relationships.
/// Copies service metadata, user information, and all custom tags/attributes.
/// </summary>
class function TObservabilityContext.CreateChild(const Parent: IObservabilityContext): IObservabilityContext;
var
  Context: TObservabilityContext;
  Key: string;
begin
  Context := TObservabilityContext.Create;
  Context.FTraceId := Parent.TraceId;
  Context.FParentSpanId := Parent.SpanId;
  Context.FServiceName := Parent.ServiceName;
  Context.FServiceVersion := Parent.ServiceVersion;
  Context.FEnvironment := Parent.Environment;
  Context.FUserId := Parent.UserId;
  Context.FUserName := Parent.UserName;
  Context.FUserEmail := Parent.UserEmail;
  
  // Copy tags and attributes
  for Key in Parent.Tags.Keys do
    Context.FTags.Add(Key, Parent.Tags[Key]);
  for Key in Parent.Attributes.Keys do
    Context.FAttributes.Add(Key, Parent.Attributes[Key]);
  
  Result := Context;
end;

/// <summary>
/// Creates a deep copy of the current context with a new span ID.
/// Maintains the same trace ID but generates a new span ID and sets current span as parent.
/// Copies all metadata, tags, and attributes to the new context.
/// </summary>
function TObservabilityContext.Clone: IObservabilityContext;
var
  C: TObservabilityContext;
  K: string;
begin
  C := TObservabilityContext.Create;
  C.FTraceId := FTraceId;
  C.FSpanId := C.GenerateId;
  C.FParentSpanId := FSpanId;
  C.FServiceName := FServiceName;
  C.FServiceVersion := FServiceVersion;
  C.FEnvironment := FEnvironment;
  C.FUserId := FUserId;
  C.FUserName := FUserName;
  C.FUserEmail := FUserEmail;
  for K in FTags.Keys do
    C.FTags.Add(K, FTags[K]);
  for K in FAttributes.Keys do
    C.FAttributes.Add(K, FAttributes[K]);
  Result := C;
end;

/// <summary>
/// Generates a unique 32-character hexadecimal identifier using GUID.
/// Removes hyphens and braces to create a clean identifier suitable for tracing systems.
/// Returns lowercase string compatible with most APM systems.
/// </summary>
function TObservabilityContext.GenerateId: string;
var
  G: TGUID;
begin
  CreateGUID(G);
  Result := GUIDToString(G).Replace('{','').Replace('}','').Replace('-','').ToLower;
end;

/// <summary>
/// Adds or updates an attribute in the context.
/// Attributes are used for storing custom metadata associated with spans and operations.
/// </summary>
procedure TObservabilityContext.AddAttribute(const Key, Value: string);
begin
  FAttributes.AddOrSetValue(Key, Value);
end;

/// <summary>
/// Adds or updates a tag in the context.
/// Tags are used for categorization and filtering in observability systems.
/// </summary>
procedure TObservabilityContext.AddTag(const Key, Value: string);
begin
  FTags.AddOrSetValue(Key, Value);
end;

function TObservabilityContext.GetAttributes: TDictionary<string,string>;
begin
  Result := FAttributes;
end;

function TObservabilityContext.GetEnvironment: string;
begin
  Result := FEnvironment;
end;

function TObservabilityContext.GetParentSpanId: string;
begin
  Result := FParentSpanId;
end;

function TObservabilityContext.GetServiceName: string;
begin
  Result := FServiceName;
end;

function TObservabilityContext.GetServiceVersion: string;
begin
  Result := FServiceVersion;
end;

function TObservabilityContext.GetSpanId: string;
begin
  Result := FSpanId;
end;

function TObservabilityContext.GetTags: TDictionary<string,string>;
begin
  Result := FTags;
end;

function TObservabilityContext.GetTraceId: string;
begin
  Result := FTraceId;
end;

function TObservabilityContext.GetUserEmail: string;
begin
  Result := FUserEmail;
end;

function TObservabilityContext.GetUserId: string;
begin
  Result := FUserId;
end;

function TObservabilityContext.GetUserName: string;
begin
  Result := FUserName;
end;

procedure TObservabilityContext.SetEnvironment(const Value: string);
begin
  FEnvironment := Value;
end;

procedure TObservabilityContext.SetParentSpanId(const Value: string);
begin
  FParentSpanId := Value;
end;

procedure TObservabilityContext.SetServiceName(const Value: string);
begin
  FServiceName := Value;
end;

procedure TObservabilityContext.SetServiceVersion(const Value: string);
begin
  FServiceVersion := Value;
end;

procedure TObservabilityContext.SetSpanId(const Value: string);
begin
  FSpanId := Value;
end;

procedure TObservabilityContext.SetTraceId(const Value: string);
begin
  FTraceId := Value;
end;

procedure TObservabilityContext.SetUserEmail(const Value: string);
begin
  FUserEmail := Value;
end;

procedure TObservabilityContext.SetUserId(const Value: string);
begin
  FUserId := Value;
end;

procedure TObservabilityContext.SetUserName(const Value: string);
begin
  FUserName := Value;
end;

end.