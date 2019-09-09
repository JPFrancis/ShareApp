bool checkIdIsFirst(String id0, String id1) {
  return id0.hashCode < id1.hashCode ? true : false;
}

/// Ids can be given in any order
Map getChatRoomData(String id0, String id1) {
  String combinedId = '';
  List users = [];

  if (checkIdIsFirst(id0, id1)) {
    combinedId = '$id0-$id1';
    users = [id0, id1];
  } else {
    combinedId = '$id1-$id0';
    users = [id1, id0];
  }

  if (combinedId.isEmpty || users.isEmpty) {
    return null;
  } else {
    return {
      'combinedId': combinedId,
      'users': users,
    };
  }
}

Map setChatUserData(Map user0, Map user1) {
  Map map = {};
  String id0 = user0['id'];
  String id0Name = user0['name'];
  String id0Avatar = user0['avatar'];
  String id1 = user1['id'];
  String id1Name = user1['name'];
  String id1Avatar = user1['avatar'];

  if (checkIdIsFirst(id0, id1)) {
    map = {
      'user0': {
        'name': id0Name,
        'avatar': id0Avatar,
      },
      'user1': {
        'name': id1Name,
        'avatar': id1Avatar,
      },
    };
  } else {
    map = {
      'user0': {
        'name': id1Name,
        'avatar': id1Avatar,
      },
      'user1': {
        'name': id0Name,
        'avatar': id0Avatar,
      },
    };
  }

  return map;
}
