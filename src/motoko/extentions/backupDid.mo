// This is a generated Motoko binding.
// Please use `import service "ic:canister_id"` instead to call canisters on the IC if possible.

module backupDid = {public type AccountIdentifier = Text;
  public type CanisterIdentifier = Text;
  public type CharactersMetadata = {
    equipment : CurrentEquipment;
    rase : Rases;
    rarityRate : RarityRate;
    ledgerCanister : CanisterIdentifier;
    state : TokenState;
    position : [Float];
    modelCanister : CanisterIdentifier;
    weapon : ?Weapons;
  };
  public type CurrentEquipment = [Nat8];
  public type RankValue = Nat;
  public type RarityRate = Float;
  public type Rases = Text;
  public type SCharacter = {
    tid : TokenIdentifier;
    canister : CanisterIdentifier;
    index : Nat32;
  };
  public type SWeapon = {
    tid : TokenIdentifier;
    canister : CanisterIdentifier;
    index : Nat32;
  };
  public type Stake = {
    aid : AccountIdentifier;
    character : SCharacter;
    rank : RankValue;
    rarityRate : Nat;
    lastClaimTime : Time;
    eGold_amount : Nat;
    startStaketime : Time;
    weapon : SWeapon;
  };
  public type StakeAdit = {
    aid : AccountIdentifier;
    character : SCharacter;
    lastClaimTime : Time;
    eAdit_amount : Nat;
    startStaketime : Time;
    weapon : SWeapon;
  };
  public type StakeCoal = {
    aid : AccountIdentifier;
    rank : RankValue;
    eCoal_amount : Nat;
    lastClaimTime : Time;
    weapon_1 : SWeapon;
    weapon_2 : SWeapon;
    startStaketime : Time;
  };
  public type StakeOre = {
    aid : AccountIdentifier;
    character : SCharacter;
    rank : RankValue;
    lastClaimTime : Time;
    startStaketime : Time;
    eOre_amount : Nat;
    weapon : SWeapon;
  };
  public type Time = Int;
  public type TokenIdentifier = Text;
  public type TokenRarity = { tokenRarity : Text };
  public type TokenState = Text;
  public type UserData = {
    aid : AccountIdentifier;
    chainmail : Text;
    dialog_count : Nat;
    body : Text;
    head : Text;
    cloak : Text;
    name : Text;
    armbands : Text;
    experience : Nat;
    shoulder : Text;
    questStep : Nat;
    gloves : Text;
    boots : Text;
    charId : TokenIdentifier;
    pants : Text;
    recipe : Text;
  };
  public type Weapons = {
    weaponType : Text;
    ledgerCanister : CanisterIdentifier;
    state : TokenState;
    modelCanister : CanisterIdentifier;
  };
  public let backupCanister = actor "f4gzx-eqaaa-aaaan-qanka-cai" : actor {
    acceptCycles : shared () -> async ();
    availableCycles : shared query () -> async Nat;
    backupSave : shared () -> async ();
    getAccount : shared () -> async [(TokenIdentifier, UserData)];
    getCharacters : shared () -> async [(TokenIdentifier, CharactersMetadata)];
    getStaked : shared () -> async [(TokenIdentifier, Stake)];
    getStakedAdit : shared () -> async [(TokenIdentifier, StakeAdit)];
    getStakedCoal : shared () -> async [(TokenIdentifier, StakeCoal)];
    getStakedOre : shared () -> async [(TokenIdentifier, StakeOre)];
    getTokensRarity : shared () -> async [(TokenIdentifier, TokenRarity)];
    getWeapons : shared () -> async [(TokenIdentifier, Weapons)];
  }
}