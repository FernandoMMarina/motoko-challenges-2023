import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Timer "mo:base/Timer";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import IC "Ic";
import Type "Types";

actor class Verifier() {
  type StudentProfile = Type.StudentProfile;
  type Result<Ok, Err> = {#err : Err; #ok : Ok};

  stable var studentProfileStoreEntries : [(Principal, StudentProfile)] = [];
  let iter = studentProfileStoreEntries.vals();

  let studentProfileStore : HashMap.HashMap<Principal, StudentProfile> = HashMap.fromIter<Principal, StudentProfile>(iter, 10, Principal.equal, Principal.hash);

  // STEP 1 - BEGIN
 
public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
  studentProfileStore.put(caller, profile);
  return #ok();
};
  public shared ({ caller }) func seeAProfile(p : Principal) : async Result.Result<StudentProfile, Text> {
    switch(studentProfileStore.get(p)) {
      case(null) { return #err("Profile not found");};
      case(?profile) { return #ok(profile);};
    };
  };

  public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    switch(studentProfileStore.get(caller)) {
      case(null) { 
          return #err("Profile not found");
        };
      case(?_) { 
          studentProfileStore.put(caller,profile);
          return #ok();
        };
    };
  };

  public shared ({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
    switch(studentProfileStore.get(caller)) {
      case(null) { return #err("profile not found") };
      case(? _) { studentProfileStore.delete(caller);return #ok();};
    };
  };

/*
  system func preupgrade(){
    studentProfileStoreEntries := Iter.toArray(studentProfileStore.entries());
  };

  system func postupgrade(){
    for((p,student) in studentProfileStoreEntries.vals()){
      studentProfileStore.put(p,student);
    };
    studentProfileStoreEntries := [];
  };*/
  
  // STEP 1 - END

  // STEP 2 - BEGIN
  type calculatorInterface = Type.CalculatorInterface;
  public type TestResult = Type.TestResult;
  public type TestError = Type.TestError;

  public func test(canisterId : Principal) : async TestResult {
    let calculator : calculatorInterface = actor(Principal.toText(canisterId));
    try{
      let result1 = await calculator.reset();
      if(result1 != 0 ){
        return #err(#UnexpectedValue("Something is wrong with the reset function"));
      };
      let result2 = await calculator.add(1);
       if(result2 != 1 ){
        return #err(#UnexpectedValue("Something is wrong with the reset function"));
      };
      let result3 = await calculator.sub(1);
       if(result3 != 0 ){
        return #err(#UnexpectedValue("Something is wrong with the reset function"));
      };
      return #ok();
    }
    catch(e){
        return #err(#UnexpectedError("Something happen when calling the calculator canister"))
    };
  };
  // STEP - 2 END

  // STEP 3 - BEGIN
  func _parseControllersFromCanisterStatusErrorIfCallerNotController(errorMessage : Text):[Principal]{
    let lines = Iter.toArray(Text.split(errorMessage, #text("\n")));
    let words = Iter.toArray(Text.split(lines[1],#text(" ")));
    var i=2;
    let controllers = Buffer.Buffer<Principal>(0);
    while(i < words.size()){
      controllers.add(Principal.fromText(words[i]));
      i+=1;
    };
    Buffer.toArray<Principal>(controllers);
  };

  // NOTE: Not possible to develop locally,
  // as actor "aaaa-aa" (aka the IC itself, exposed as an interface) does not exist locally
  public func verifyOwnership(canisterId : Principal, principalId : Principal) : async Bool {
  
        let managementCanister : IC.ManagementCanisterInterface = actor ("aaaaa-aa");
        try {
            let statusCanister = await managementCanister.canister_status({canister_id = canisterId});
            let controllers = statusCanister.settings.controllers;
            //let controllers_text = Array.map<Principal, Text>(controllers, func x = Principal.toText(x));
            for(p in controllers.vals()){
                if(p == principalId){
                  return true;
                };
            };
            return false;
        }catch (e){
          let message = Error.message(e);
          let controllers = _parseControllersFromCanisterStatusErrorIfCallerNotController(message);
          for(p in controllers.vals()){
              if(p==principalId){
                return true;
              };
          };
          return false;
        };
        };
  // STEP 3 - END

  // STEP 4 - BEGIN
  public shared ({ caller }) func verifyWork(canisterId : Principal, p : Principal) : async Result.Result<(), Text> {
    let isOwner = await verifyOwnership(canisterId,p);
    if(not (isOwner)){
      return #err("The caller is not the owner of the canister");
    };
    let result = await test(canisterId);
    switch(result) {
      case(#err(_)) {return #err("The canister does not pass the tests")  };
      case(#ok()) { 
          switch(studentProfileStore.get(p)) {
            case(null) {
               return #err("Profile not found")
                };
            case(?profile) { 
              let newProfile = {
                name = profile.name;
                team = profile.team;
                graduate = true;
              };
              studentProfileStore.put(p,newProfile);
              return #ok();
            };
          };
      };
    };
  };

  
  // STEP 4 - END
};