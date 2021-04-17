

import 'package:inventary/db/ItemDAO.dart';
import 'package:inventary/db/database.dart';
import 'package:inventary/model/ItemEntity.dart';

class ItemRepository {

  final ItemDAO itemDAO = AppDatabase().getItemDAO();

  Future<int> insert(ItemEntity item) {
    return itemDAO.insert(item);
  }

  Future<void> update(ItemEntity item) {
    return itemDAO.update(item);
  }

  Future<void> delete(int id) {
    return itemDAO.delete(id);
  }

  Future<List<ItemEntity>> list([int parent = -1]) {
    return itemDAO.list(parent);
  }

  Future<List<ItemEntity>> search({
    required String nameFilter,
    required bool nameFilterAsc,
    required List<String> friendsFilter,
    required List<int> folderFilter,
  }) {
    return itemDAO.search(
      nameFilter: nameFilter,
      nameFilterAsc: nameFilterAsc,
      friendsFilter: friendsFilter,
      folderFilter: folderFilter,
    );
  }

  Future<void> changeParent(int to, int from) {
    return itemDAO.changeParent(to, from);
  }

  Future<void> move(int id, int newParent) {
    return itemDAO.move(id, newParent);
  }

  Future<List<ItemEntity>> listRootFolders() {
    return itemDAO.listRootFolders();
  }

  Future<List<String>> listFriends() {
    return itemDAO.listFriends();
  }

}