// This is a generated Motoko binding.
// Please use `import service "ic:canister_id"` instead to call canisters on the IC if possible.
module eBronze = {
   public type Account = { owner : Principal; subaccount : ?SubAccount };
  public type AccountIdentifier = Text;
  public type AccountIdentifier__1 = Text;
  public type Account__1 = { owner : Principal; subaccount : ?Subaccount };
  public type Asset = { name : Text; payload : File };
  public type Balance = Nat;
  public type CanisterMemorySize = Nat;
  public type Eimolad_ICRC1_Transfer = {
    to : User;
    fee : ?Tokens;
    from : User;
    memo : ?Memo;
    created_at_time : ?Timestamp;
    amount : Tokens;
  };
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
  public type ICRC1_Transfer = {
    to : Account__1;
    fee : ?Tokens;
    memo : ?Memo;
    from_subaccount : ?Subaccount;
    created_at_time : ?Timestamp;
    amount : Tokens;
  };
  public type Memo = [Nat8];
  public type Result = { #ok : Text; #err };
  public type ResultTrans = { trans : [Transaction]; size : Nat32 };
  public type SubAccount = [Nat8];
  public type Subaccount = Blob;
  public type Time = Int;
  public type Timestamp = Nat64;
  public type TokenInfo = {
    token_symbol : Text;
    token_canister : Text;
    CB_capacity : Nat;
    current_CB_value : Balance;
    token_standart : Text;
    min_CB_value : Nat;
    snsCanister : Text;
    royaltyWallet : Text;
    royalty : Nat;
  };
  public type Tokens = Nat;
  public type Transaction = {
    fee : Tokens;
    args : Transfer;
    kind : TxKind;
    timestamp : Timestamp;
  };
  public type Transfer = {
    to : User;
    fee : ?Tokens;
    from : User;
    memo : ?Memo;
    created_at_time : ?Timestamp;
    amount : Tokens;
  };
  public type TransferError = {
    #GenericError : { message : Text; error_code : Nat };
    #TemporarilyUnavailable;
    #BadBurn : { min_burn_amount : Tokens };
    #Duplicate : { duplicate_of : TxIndex };
    #BadFee : { expected_fee : Tokens };
    #CreatedInFuture : { ledger_time : Timestamp };
    #TooOld;
    #InsufficientFunds : { balance : Tokens };
  };
  public type TransferResult = { #Ok : Tokens; #Err : TransferError };
  public type TxIndex = Nat;
  public type TxKind = { #Burn; #Mint; #Transfer };
  public type User = { #principal : Account; #address : AccountIdentifier };
  public type Value = { #Int : Int; #Nat : Nat; #Blob : [Nat8]; #Text : Text };
  public let eBronzeCanister = actor "si6du-ciaaa-aaaan-qarra-cai" : actor {
    acceptCycles : shared () -> async ();
    addAsset : shared Asset -> async Nat;
    availableCycles : shared query () -> async Nat;
    changeCapacity : shared Nat -> async Result;
    changeFeeCheckTime : shared Time -> async Result;
    changeFeeWallet : shared AccountIdentifier__1 -> async Result;
    changeICRCfee : shared Nat -> async Result;
    changeMinCanisterSupply : shared Nat -> async Result;
    changeSum : shared Nat -> async Result;
    changefee : shared Nat -> async Result;
    eimolad_balance : shared User -> async Balance;
    eimolad_icrc1_transfer : shared Eimolad_ICRC1_Transfer -> async TransferResult;
    findTransactions : shared AccountIdentifier__1 -> async [Transaction];
    getBalances : shared () -> async [(AccountIdentifier__1, Balance)];
    getCanisterMemorySize : shared () -> async CanisterMemorySize;
    getCapacity : shared () -> async Nat;
    getCirculateBalance : shared () -> async Nat;
    getFee : shared () -> async Nat;
    getFeeCheckTime : shared () -> async Time;
    getFeeWallet : shared () -> async AccountIdentifier__1;
    getICRCTransactions : shared (Nat32, Nat32) -> async ResultTrans;
    getMinCanisterSupply : shared () -> async Nat;
    getSum : shared () -> async Nat;
    getTokenInfo : shared () -> async TokenInfo;
    http_request : shared query HttpRequest -> async HttpResponse;
    http_request_streaming_callback : shared query HttpStreamingCallbackToken -> async HttpStreamingCallbackResponse;
    icrc1_balance_of : shared query Account__1 -> async Nat;
    icrc1_decimals : shared query () -> async Nat8;
    icrc1_fee : shared query () -> async Nat;
    icrc1_metadata : shared query () -> async [(Text, Value)];
    icrc1_minting_account : shared query () -> async ?Account__1;
    icrc1_name : shared query () -> async Text;
    icrc1_supported_standards : shared query () -> async [
        { url : Text; name : Text }
      ];
    icrc1_symbol : shared query () -> async Text;
    icrc1_total_supply : shared query () -> async Tokens;
    icrc1_transfer : shared ICRC1_Transfer -> async TransferResult;
    icrc_1_TransferToPrincipal : shared (
        Text,
        ?Subaccount,
        Nat,
      ) -> async TransferResult;
    rewriteAsset : shared (Text, Asset) -> async ?Nat;
    streamAsset : shared (Nat, Bool, [Nat8]) -> async ();
    transferFromCanister : shared (User, Nat) -> async TransferResult;
    transferFromCanisterToPrincipal : shared (
        Text,
        ?Subaccount,
        Nat,
      ) -> async TransferResult;
  }
}