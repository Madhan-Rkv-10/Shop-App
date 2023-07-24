import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart.dart';
import '../screens/cart_screen.dart';
import '../widgets/app_drawer.dart';
import '../widgets/products_grid.dart';
import '../widgets/badge.dart' as badge;
import '../providers/product_provider.dart';

enum FilterOptions { fav, All }

class ProductOverview extends StatefulWidget {
  const ProductOverview({super.key});

  @override
  State<ProductOverview> createState() => _ProductOverviewState();
}

class _ProductOverviewState extends State<ProductOverview> {
  bool _showOnlyFav = false;
  bool _isInit = true;
  bool _isLoading = false;
  @override
  void initState() {
    // Provider.of<Products>(context).fetchAndSetProduct(); //wont work
    // Future.delayed(Duration.zero).then((value) {
    //   Provider.of<Products>(context).fetchAndSetProduct();
    // });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });
      Provider.of<Products>(context).fetchAndSetProduct().then((value) {
        setState(() {
          _isLoading = false;
        });
      });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // final productcontroller = Provider.of<Products>(context, listen: false);

    // final cart=Provider.of<Cart>(context) ;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showOnlyFav ? 'Your Favorites' : 'All Products',
        ),
        actions: [
          PopupMenuButton(
              onSelected: (FilterOptions selectedValue) {
                setState(() {
                  if (selectedValue == FilterOptions.All) {
                    // productcontroller.showAll();
                    _showOnlyFav = false;
                  } else {
                    // productcontroller.shoFav();
                    _showOnlyFav = true;
                  }
                });

                // print(selectedValue);
              },
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: FilterOptions.fav,
                      child: Text('Only fav'),
                    ),
                    PopupMenuItem(
                      value: FilterOptions.All,
                      child: Text('show all'),
                    ),
                  ]),
          Consumer<Cart>(
              builder: (_, cartdata, ch) => badge.Badge(
                    value: cartdata.itemCount.toString(),
                    child: ch as Widget,
                  ),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.of(context).pushNamed(CartScreen.routeName);
                },
              )),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.pink,
                backgroundColor: Colors.green,
                strokeWidth: 4.0,
                semanticsLabel: 'Madhan',
              ),
            )
          : ProductGrid(showFavorite: _showOnlyFav),
    );
  }
}
