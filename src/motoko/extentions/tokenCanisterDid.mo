// This is a generated Motoko binding.
// Please use `import service "ic:canister_id"` instead to call canisters on the IC if possible.

module tokenCanisterDid = {
  public type AccountIdentifier = Text;
  public type AccountIdentifier__1 = Text;
  public type ApproveRequest = {
    token : TokenIdentifier;
    subaccount : ?SubAccount;
    allowance : Balance;
    spender : Principal;
  };
  public type Asset = { name : Text; payload : File };
  public type Balance = Nat;
  public type BalanceRequest = { token : TokenIdentifier; user : User__1 };
  public type BalanceResponse = { #ok : Balance; #err : CommonError__1 };
  public type Balance__1 = Nat;
  public type CanisterMemorySize = Nat;
  public type CommonError = { #InvalidToken : TokenIdentifier; #Other : Text };
  public type CommonError__1 = {
    #InvalidToken : TokenIdentifier;
    #Other : Text;
  };
  public type Extension = Text;
  public type File = { data : [[Nat8]]; ctype : Text };
  public type HeaderField = (Text, Text);
  public type HttpRequest = {
    url : Text;
    method : Text;
    body : [Nat8];
    headers : [HeaderField];
  };
  public type HttpResponse = {
    body : [Nat8];
    headers : [HeaderField];
    streaming_strategy : ?HttpStreamingStrategy;
    status_code : Nat16;
  };
  public type HttpStreamingCallbackResponse = {
    token : ?HttpStreamingCallbackToken;
    body : [Nat8];
  };
  public type HttpStreamingCallbackToken = {
    key : Text;
    sha256 : ?[Nat8];
    index : Nat;
    content_encoding : Text;
  };
  public type HttpStreamingStrategy = {
    #Callback : {
      token : HttpStreamingCallbackToken;
      callback : shared query HttpStreamingCallbackToken -> async HttpStreamingCallbackResponse;
    };
  };
  public type Memo = [Nat8];
  public type Metadata = {
    #fungible : {
      decimals : Nat8;
      metadata : ?[Nat8];
      name : Text;
      symbol : Text;
    };
    #nonfungible : { metadata : ?[Nat8] };
  };
  public type Result = { #ok : Balance__1; #err : CommonError };
  public type Result_1 = { #ok : Metadata; #err : CommonError };
  public type Result_2 = { #ok : Text; #err };
  public type SubAccount = [Nat8];
  public type Time = Int;
  public type TokenIdentifier = Text;
  public type TokenIdentifier__1 = Text;
  public type TransferId = Nat32;
  public type TransferInfo = {
    to : User;
    token : TokenIdentifier__1;
    from : User;
    time : Time;
    amount : Nat;
  };
  public type TransferRequest = {
    to : User__1;
    token : TokenIdentifier;
    notify : Bool;
    from : User__1;
    memo : Memo;
    subaccount : ?SubAccount;
    amount : Balance;
  };
  public type TransferResponse = {
    #ok : Balance;
    #err : {
      #CannotNotify : AccountIdentifier;
      #InsufficientBalance;
      #InvalidToken : TokenIdentifier;
      #Rejected;
      #Unauthorized : AccountIdentifier;
      #Other : Text;
    };
  };
  public type User = { #principal : Principal; #address : AccountIdentifier };
  public type User__1 = {
    #principal : Principal;
    #address : AccountIdentifier;
  };
  public type tokenCanisterActor = actor {
    acceptCycles : shared () -> async ();
    addAsset : shared Asset -> async Nat;
    approve : shared ApproveRequest -> async ();
    availableCycles : shared query () -> async Nat;
    balance : shared query BalanceRequest -> async BalanceResponse;
    changeFeeCheckTime : shared Time -> async Result_2;
    changeFeeWallet : shared AccountIdentifier__1 -> async Result_2;
    changeSum : shared Nat -> async Result_2;
    changefee : shared Nat -> async Result_2;
    extensions : shared query () -> async [Extension];
    findTransactions : shared AccountIdentifier__1 -> async [TransferInfo];
    getBalances : shared () -> async [(AccountIdentifier__1, Balance__1)];
    getCanisterMemorySize : shared () -> async CanisterMemorySize;
    getCirculateBalance : shared () -> async Nat;
    getFee : shared () -> async Nat;
    getFeeCheckTime : shared () -> async Time;
    getFeeWallet : shared () -> async AccountIdentifier__1;
    getSum : shared () -> async Nat;
    getSupply : shared () -> async Nat32;
    getTotalSupply : shared () -> async Nat32;
    getTransactions : shared () -> async [(TransferId, TransferInfo)];
    http_request : shared query HttpRequest -> async HttpResponse;
    http_request_streaming_callback : shared query HttpStreamingCallbackToken -> async HttpStreamingCallbackResponse;
    metadata : shared query TokenIdentifier__1 -> async Result_1;
    rewriteAsset : shared (Text, Asset) -> async ?Nat;
    streamAsset : shared (Nat, Bool, [Nat8]) -> async ();
    supply : shared query TokenIdentifier__1 -> async Result;
    transfer : shared TransferRequest -> async TransferResponse;
    transferFromCanister : shared (Nat, User) -> async TransferResponse;
  }
}