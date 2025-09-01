import '../database/database_helper.dart';

class ItemService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Report lost or found item
  Future<Map<String, dynamic>> reportItem({
    required String title,
    required String description,
    required String category,
    required String location,
    required String status, // 'lost' or 'found'
    required int userId,
    String? imagePath,
    String? contactInfo,
  }) async {
    try {
      // Validate inputs
      if (title.isEmpty) {
        return {'success': false, 'message': 'Item title is required'};
      }

      if (description.isEmpty) {
        return {'success': false, 'message': 'Item description is required'};
      }

      if (category.isEmpty) {
        return {'success': false, 'message': 'Please select a category'};
      }

      if (location.isEmpty) {
        return {'success': false, 'message': 'Location is required'};
      }

      if (status != 'lost' && status != 'found') {
        return {'success': false, 'message': 'Invalid status'};
      }

      // Report item
      final itemId = await _databaseHelper.reportItem(
        title: title,
        description: description,
        category: category,
        location: location,
        status: status,
        userId: userId,
        imagePath: imagePath,
        contactInfo: contactInfo,
      );

      if (itemId > 0) {
        return {
          'success': true,
          'message': 'Item reported successfully!',
          'itemId': itemId,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to report item. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Get all items
  Future<List<Map<String, dynamic>>> getAllItems({String? status}) async {
    try {
      return await _databaseHelper.getItems(status: status);
    } catch (e) {
      return [];
    }
  }

  // Get items by user
  Future<List<Map<String, dynamic>>> getItemsByUser(int userId) async {
    try {
      return await _databaseHelper.getItemsByUser(userId);
    } catch (e) {
      return [];
    }
  }

  // Search items
  Future<List<Map<String, dynamic>>> searchItems({
    String? query,
    String? category,
    String? status,
  }) async {
    try {
      return await _databaseHelper.searchItems(
        query: query,
        category: category,
        status: status,
      );
    } catch (e) {
      return [];
    }
  }

  // Claim item
  Future<Map<String, dynamic>> claimItem(int itemId, int claimingUserId) async {
    try {
      // Get item details
      final item = await _databaseHelper.getItemById(itemId);

      if (item == null) {
        return {'success': false, 'message': 'Item not found'};
      }

      if (item['status'] == 'claimed') {
        return {'success': false, 'message': 'Item has already been claimed'};
      }

      if (item['userId'] == claimingUserId) {
        return {'success': false, 'message': 'You cannot claim your own item'};
      }

      // Update item status to claimed with claiming user ID
      final result = await _databaseHelper.updateItemStatus(
        itemId,
        'claimed',
        claimedByUserId: claimingUserId,
      );

      if (result > 0) {
        return {
          'success': true,
          'message':
              'Item claimed successfully! Contact the person who posted this item.',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to claim item. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Mark lost item as found by owner
  Future<Map<String, dynamic>> markItemAsFound(
    int itemId,
    int ownerUserId,
  ) async {
    try {
      // Get item details
      final item = await _databaseHelper.getItemById(itemId);

      if (item == null) {
        return {'success': false, 'message': 'Item not found'};
      }

      if (item['userId'] != ownerUserId) {
        return {
          'success': false,
          'message': 'You can only mark your own items as found',
        };
      }

      if (item['status'] != 'lost') {
        return {
          'success': false,
          'message': 'Only lost items can be marked as found',
        };
      }

      // Update item status to found
      final result = await _databaseHelper.updateItemStatus(itemId, 'found');

      if (result > 0) {
        return {
          'success': true,
          'message': 'Item marked as found successfully!',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to mark item as found. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Get item by ID
  Future<Map<String, dynamic>?> getItemById(int itemId) async {
    try {
      return await _databaseHelper.getItemById(itemId);
    } catch (e) {
      return null;
    }
  }

  // Get user details for an item
  Future<Map<String, dynamic>?> getItemUserDetails(int userId) async {
    try {
      return await _databaseHelper.getUserById(userId);
    } catch (e) {
      return null;
    }
  }

  // Add comment to item
  Future<Map<String, dynamic>> addComment({
    required int itemId,
    required int userId,
    required String comment,
  }) async {
    try {
      if (comment.trim().isEmpty) {
        return {'success': false, 'message': 'Comment cannot be empty'};
      }

      final commentId = await _databaseHelper.addComment(
        itemId: itemId,
        userId: userId,
        comment: comment.trim(),
      );

      if (commentId > 0) {
        return {
          'success': true,
          'message': 'Comment added successfully!',
          'commentId': commentId,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to add comment. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Get comments for an item
  Future<List<Map<String, dynamic>>> getCommentsForItem(int itemId) async {
    try {
      return await _databaseHelper.getCommentsForItem(itemId);
    } catch (e) {
      return [];
    }
  }

  // Delete comment
  Future<Map<String, dynamic>> deleteComment(int commentId) async {
    try {
      final result = await _databaseHelper.deleteComment(commentId);

      if (result > 0) {
        return {'success': true, 'message': 'Comment deleted successfully!'};
      } else {
        return {
          'success': false,
          'message': 'Failed to delete comment. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Delete item
  Future<Map<String, dynamic>> deleteItem(int itemId) async {
    try {
      final result = await _databaseHelper.deleteItem(itemId);

      if (result > 0) {
        return {'success': true, 'message': 'Item deleted successfully!'};
      } else {
        return {
          'success': false,
          'message': 'Failed to delete item. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
}
