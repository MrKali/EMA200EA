input int take_profit_em_pontos = 300;
input double tamanho_do_lote = 0.01;
input bool trade_apenas_com_swap_positivo = true;
input int afastamento_de_ordens_buy_em_pontos = 0;
input int afastamento_de_ordens_sell_em_pontos = 0;
input int afastamento_de_ema_minimo_sell_em_pontos = 0;
input int afastamento_de_ema_minimo_buy_em_pontos = 0;
input int magic_number = 5431;

input double balanceToIncrease = 1000;
input double lotSizeToIncrease = 0.01;

void OnTick(){ 
   double ema200 = iMA(_Symbol, _Period, 200, 0, MODE_EMA, PRICE_CLOSE, 1);

   // get last bar price
   double closePriceOfLastBar = Close[1];
   double openPriceOfLastBar = Open[1];
   
   bool sellCondition = closePriceOfLastBar > ema200 && closePriceOfLastBar > openPriceOfLastBar && IsSwapTradable(OP_SELL) && HasEnoughDifferenceToOpenASellOrder() && HasEnoughDistanceFromEmaToSell();
   bool buyCondition = closePriceOfLastBar < ema200 && closePriceOfLastBar < openPriceOfLastBar && IsSwapTradable(OP_BUY) && HasEnoughDifferenceToOpenABuyOrder() && HasEnoughDistanceFromEmaToBuy();
   
   if(NewBar()){
        if (buyCondition){
            OrderSend (_Symbol, OP_BUY, GetLotSizeByBalance(lotSizeToIncrease, balanceToIncrease) , Ask, 3, 0, Ask+GetTakeProfitAtr(), NULL, magic_number, 0, Green);
        } else if (sellCondition){
            OrderSend (_Symbol, OP_SELL, GetLotSizeByBalance(lotSizeToIncrease, balanceToIncrease), Bid, 3, 0,Bid-GetTakeProfitAtr(), NULL, magic_number, 0, Red); 
        }
   }               
}

bool HasEnoughDifferenceToOpenABuyOrder(){
   double biggestPrice = 0.0;
   int Count=0;
   
   if (OrdersTotal() == 0) return true;
   
   for (int i = OrdersTotal(); i >=0; i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderMagicNumber()== magic_number && OrderSymbol()== _Symbol){
         if (Count == 0){
            biggestPrice = OrderOpenPrice();
         }
         
         Count=Count+1;
         
         if (biggestPrice > OrderOpenPrice()){
             biggestPrice = OrderOpenPrice();
         }
      }
   }
   
    double DiffPoints = MathAbs(NormalizeDouble(Close[1] - biggestPrice,Digits)/Point);
    if (DiffPoints >= afastamento_de_ordens_buy_em_pontos){
      return true;
    }
   
   return false;
}

bool HasEnoughDifferenceToOpenASellOrder(){
   double lowestPrice = 0.0;
   int Count=0;
   
   if (OrdersTotal() == 0) return true;
   
   for (int i = OrdersTotal(); i >=0; i--) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderMagicNumber()== magic_number && OrderSymbol()== _Symbol){
         if (Count == 0){
            lowestPrice = OrderOpenPrice();
         }
         
         Count=Count+1;
         
         if (lowestPrice < OrderOpenPrice()){
             lowestPrice = OrderOpenPrice();
         }
      }
   }
   
   double DiffPoints = MathAbs(NormalizeDouble(lowestPrice - Close[1],Digits)/Point);
   if (DiffPoints >= afastamento_de_ordens_sell_em_pontos){
      return true;
   }
   
   return false;
}

bool HasEnoughDistanceFromEmaToBuy(){
   double ema200 = iMA(_Symbol, _Period, 200, 0, MODE_EMA, PRICE_CLOSE, 1);
   double DiffPoints = MathAbs(NormalizeDouble(Close[1] - ema200,Digits)/Point);
   
      Comment(DiffPoints);
   if (DiffPoints > afastamento_de_ema_minimo_buy_em_pontos){
      return true;
   }else{
      return false;
   }
}

bool HasEnoughDistanceFromEmaToSell(){
   double ema200 = iMA(_Symbol, _Period, 200, 0, MODE_EMA, PRICE_CLOSE, 1);
   double DiffPoints = MathAbs(NormalizeDouble(Close[1] - ema200,Digits)/Point);
   
   if (DiffPoints > afastamento_de_ema_minimo_sell_em_pontos){
      return true;
   }else{
      return false;
   }
}

bool IsSwapTradable(int operationType){
   if (!trade_apenas_com_swap_positivo){
       return true;
   }else{
      double swapLong = SymbolInfoDouble(_Symbol, SYMBOL_SWAP_LONG);
      double swapShort = SymbolInfoDouble(_Symbol, SYMBOL_SWAP_SHORT);
      
      if (operationType == OP_BUY && swapLong < 0){
         return false;
      }else if (operationType == OP_SELL && swapShort < 0){
         return false;
      }else{
         return true;
      }
      
      return false;
   }
}



bool NewBar(){ 
   static datetime lastbar;
   
   if (Time[0] == lastbar){
      return false;
   }else{
      lastbar = Time[0];
      return true;
   }
}

double GetLotSizeByBalance(double lotSizePerBalance, double balanceToIncrease){
   double lotSize = (AccountBalance() * lotSizePerBalance)/balanceToIncrease;
  
   if ( NormalizeDouble(lotSize, 2) < 0.01) return 0.01;
   
   return  NormalizeDouble(lotSize, 2);
}

double GetTakeProfitAtr(){
   return (iATR(Symbol(), PERIOD_D1, 14, 1)*4) * GetMultiplierPoint() *_Point;
   //return take_profit_em_pontos *_Point;
}

int GetMultiplierPoint()
  {
   double digits = MarketInfo(Symbol(), MODE_DIGITS);

   if(digits == 2)
     {
      return 10;
     }
   else
      if(digits == 3)
        {
         return 100;
        }
      else
         if(digits == 4)
           {
            return 1000;
           }
         else
            if(digits == 5)
              {
               return 10000;
              }
            else
              {
               return 0;
              }
  }


  
