import Type "Types";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import Order "mo:base/Order"; 
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Int "mo:base/Int";

actor class StudentWall() {
  type Message = Type.Message;
  type Content = Type.Content;
  type Survey = Type.Survey;
  type Answer = Type.Answer;

  //var nextMessageId : Nat = initialMessageId;
  //var wall = HashMap.HashMap<Nat,Message>(1,Nat.equal,Hash.hash);
  //private func _hashNat(n:Nat) : Hash.Hash = return Text.hash(Nat.toText(n));
  let natHash = func (n:Nat):Hash.Hash = Text.hash(Nat.toText(n));
  var wall = HashMap.HashMap<Nat,Message>(5,Nat.equal,natHash);

  stable var messageId : Nat = 0;
 
  // Add a new message to the wall
  public shared ({ caller }) func writeMessage(c : Content) : async Nat {

    let newMessageId : Nat = messageId;
    messageId := messageId + 1;
    let newMessage : Message = {
      content = c;
      vote = 0;
      creator = caller;
    };
    wall.put(newMessageId, newMessage);

    return newMessageId;
  };

  // Get a specific message by ID
  
public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {

        let message : ?Message = wall.get(messageId);

        switch(message) {
            case(null){
                #err("Message not found");
            };
            case(?m){
                #ok(m);
            };
        };
    };

  // Update the content for a specific message by ID
  public shared ({ caller }) func updateMessage(messageId : Nat, c : Content) : async Result.Result<(), Text> {
    let validator : ?Message = wall.get(messageId);
   
    switch(validator) {
      case(null) {
          return #err("Error");
        };
      case(?currentMessage){
          if(Principal.equal(currentMessage.creator,caller)){
            let msg ={
              vote = currentMessage.vote;
              content = c;
              creator = currentMessage.creator;
            };
            wall.put(messageId,msg);
            return #ok();
          }
          else{
            return #err("Error#")
          }
       };
    };
  };

  // Delete a specific message by ID
  public shared ({ caller }) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
    if((messageId <= 0) and (messageId < wall.size())){
        wall.delete(messageId);
        return #ok();
    }
    else{
      return #err("Message ID requested is invalid--DeleteMessage");
    }
  };

  // Voting
  public func upVote(messageId : Nat) : async Result.Result<(), Text> {
    switch(wall.get(messageId)) {
      case(null) { 
        return #err("Error trying obtain message");
       };
      case(?message) { 
        let newMsg : Message = {content = message.content; vote = message.vote+1; creator = message.creator;};
        ignore wall.replace(messageId,newMsg);
        return #ok();
      };
    };
  };

  public func downVote(messageId : Nat) : async Result.Result<(), Text> {
    switch(wall.get(messageId)) {
      case(null) { 
        return #err("Error trying obtain message");
       };
      case(?message) { 
        let newMsg : Message = {content = message.content; vote = message.vote-1; creator = message.creator;};
        ignore wall.replace(messageId,newMsg);
        return #ok();
      };
    };
  };


  // Get all messages
  public func getAllMessages() : async [Message] {
    return Iter.toArray<Message>(wall.vals());
  };

  type Order = Order.Order;
  func compareMessage ( m1:Message , m2:Message ):Order{
    if(m1.vote == m2.vote){
        return #equal;
    };
    if(m1.vote == m2.vote){
        return #less;
    };
    return #greater;
  };

  // Get all messages ordered by votes
   public func getAllMessagesRanked() : async [Message] {
    let sortedMessages=Iter.sort<Message>(wall.vals(),func(x,y)= Int.compare(y.vote, x.vote));
    return Iter.toArray(sortedMessages);
  };
};
