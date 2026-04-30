import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String name;
  final String email;
  final String role;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:    json['id']    as int,
    name:  json['name']  as String,
    email: json['email'] as String,
    role:  json['role']  as String,
  );

  @override
  List<Object?> get props => [id, email, role];
}

class FarmerModel extends Equatable {
  final int id;
  final String identifier;
  final String firstname;
  final String lastname;
  final String? phone;
  final String? village;
  final int creditLimitFcfa;
  final bool isActive;

  const FarmerModel({
    required this.id,
    required this.identifier,
    required this.firstname,
    required this.lastname,
    this.phone,
    this.village,
    required this.creditLimitFcfa,
    required this.isActive,
  });

  String get fullName => '$firstname $lastname';

  factory FarmerModel.fromJson(Map<String, dynamic> json) => FarmerModel(
    id:              json['id']               as int,
    identifier:      json['identifier']       as String,
    firstname:       json['firstname']        as String,
    lastname:        json['lastname']         as String,
    phone:           json['phone']            as String?,
    village:         json['village']          as String?,
    creditLimitFcfa: json['credit_limit_fcfa'] as int,
    isActive:        json['is_active'] == true || json['is_active'] == 1,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'identifier': identifier,
    'firstname': firstname, 'lastname': lastname,
    'phone': phone, 'village': village,
    'credit_limit_fcfa': creditLimitFcfa, 'is_active': isActive,
  };

  @override
  List<Object?> get props => [id, identifier];
}

class CategoryModel extends Equatable {
  final int id;
  final String name;
  final String slug;
  final int? parentId;
  final List<CategoryModel> children;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.children = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id:       json['id']        as int,
    name:     json['name']      as String,
    slug:     json['slug']      as String,
    parentId: json['parent_id'] as int?,
    children: (json['children'] as List<dynamic>? ?? [])
        .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
        .toList(),
  );

  @override
  List<Object?> get props => [id, slug];
}

class ProductModel extends Equatable {
  final int id;
  final String name;
  final int priceFcfa;
  final String unit;
  final int categoryId;
  final String? categoryName;

  const ProductModel({
    required this.id,
    required this.name,
    required this.priceFcfa,
    required this.unit,
    required this.categoryId,
    this.categoryName,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id:           json['id']         as int,
    name:         json['name']       as String,
    priceFcfa:    json['price_fcfa'] as int,
    unit:         json['unit']       as String,
    categoryId:   json['category_id'] as int,
    categoryName: (json['category'] as Map<String, dynamic>?)?['name'] as String?,
  );

  @override
  List<Object?> get props => [id];
}

class DebtModel extends Equatable {
  final int id;
  final int farmerId;
  final int transactionId;
  final double originalAmountFcfa;
  final double remainingAmountFcfa;
  final bool isSettled;
  final DateTime createdAt;

  const DebtModel({
    required this.id,
    required this.farmerId,
    required this.transactionId,
    required this.originalAmountFcfa,
    required this.remainingAmountFcfa,
    required this.isSettled,
    required this.createdAt,
  });

  double get percentPaid =>
      originalAmountFcfa > 0 ? (originalAmountFcfa - remainingAmountFcfa) / originalAmountFcfa : 0;

  factory DebtModel.fromJson(Map<String, dynamic> json) => DebtModel(
    id:                   json['id']                    as int,
    farmerId:             json['farmer_id']             as int,
    transactionId:        json['transaction_id']        as int,
    originalAmountFcfa:   (json['original_amount_fcfa']  as num).toDouble(),
    remainingAmountFcfa:  (json['remaining_amount_fcfa'] as num).toDouble(),
    isSettled:            json['is_settled'] == true || json['is_settled'] == 1,
    createdAt:            DateTime.parse(json['created_at'] as String),
  );

  @override
  List<Object?> get props => [id];
}

class CartItem extends Equatable {
  final ProductModel product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  double get subtotal => product.priceFcfa * quantity.toDouble();

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);

  @override
  List<Object?> get props => [product.id, quantity];
}
