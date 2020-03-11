enum MA_Method
 {
   Simple = 0,
   Exponential = 1,
   Smoothed = 2,
   LinearWeighted = 3
};

static input string MA_DEFINICOES = "====== MÉDIA MÓVEL ======";
input int Periodo = 200;
input MA_Method Metodo = Exponential;

static input string GESTAO_RISCO = "====== GESTÃO DE RISCO ======";
input int take_profit_em_pontos = 300;
input double tamanho_do_lote = 0.01;
input int Margem_minima = 3000;

static input string DISTANCIAMENTO = "====== DISTANCIAMENTO ======";
input int afastamento_de_ordens_buy_em_pontos = 0;
input int afastamento_de_ordens_sell_em_pontos = 0;
input int afastamento_de_ema_minimo_sell_em_pontos = 0;
input int afastamento_de_ema_minimo_buy_em_pontos = 0;

static input string RSI = "====== RSI ======";
input bool Rsi_ativado = false;
input int Rsi_periodo = 14;
input int Rsi_Nivel_sobrevenda = 30;
input int Rsi_Nivel_sobrecompra = 70;

static input string ESTOCASTICO = "====== ESTOCÁSTICO ======";
input bool Estocastico_ativado = false;
input int Estocastico_Nivel_sobrevenda = 20;
input int Estocastico_Nivel_sobrecompra = 80;
input int Estocastico_K = 5;
input int Estocastico_D = 3;
input int Estocastico_Smooth = 3;
input MA_Method Estocastico_MA_Metodo = Simple;

static input string OUTROS = "====== OUTROS ======";
input bool trade_apenas_com_swap_positivo = true;
input int magic_number = 5431;

void OnTick(){ 
   double ema200 = iMA(_Symbol, _Period, Periodo, 0, Metodo, PRICE_CLOSE, 1);

   // get last bar price
   double closePriceOfLastBar = Close[1];
   double openPriceOfLastBar = Open[1];
   
   bool sellCondition = closePriceOfLastBar > ema200 && closePriceOfLastBar > openPriceOfLastBar && IsSwapTradable(OP_SELL) && HasEnoughDifferenceToOpenASellOrder() && HasEnoughDistanceFromEmaToSell() && CheckIfThereIsEnoughtMargin() && CheckStochasticFilter(OP_SELL) && CheckRsiFilter(OP_SELL);
   bool buyCondition = closePriceOfLastBar < ema200 && closePriceOfLastBar < openPriceOfLastBar && IsSwapTradable(OP_BUY) && HasEnoughDifferenceToOpenABuyOrder() && HasEnoughDistanceFromEmaToBuy() && CheckIfThereIsEnoughtMargin() && CheckStochasticFilter(OP_BUY) && CheckRsiFilter(OP_BUY);
   
   if(NewBar()){
        if (buyCondition){
            OrderSend (_Symbol, OP_BUY, tamanho_do_lote, Ask, 3, 0, Ask+take_profit_em_pontos*_Point, NULL, magic_number, 0, Green);
        } else if (sellCondition){
            OrderSend (_Symbol, OP_SELL, tamanho_do_lote, Bid, 3, 0,Bid-take_profit_em_pontos*_Point, NULL, magic_number, 0, Red); 
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

bool CheckIfThereIsEnoughtMargin(){
   double availableMargin = AccountFreeMargin();
   if (availableMargin < Margem_minima){
      return false;
   }else{
      return true;
   }
}

bool CheckStochasticFilter(int order_type){
   if (Estocastico_ativado){
      double K0 = iStochastic(_Symbol, _Period, Estocastico_K, Estocastico_D, Estocastico_Smooth, Estocastico_MA_Metodo, 0, MODE_MAIN, 1);
      double D0 = iStochastic(_Symbol, _Period, Estocastico_K, Estocastico_D, Estocastico_Smooth, Estocastico_MA_Metodo, 0, MODE_SIGNAL, 1);
      
      if (order_type == OP_BUY && K0 < Estocastico_Nivel_sobrevenda && D0 < Estocastico_Nivel_sobrevenda){
         return true;
      }else if (order_type == OP_SELL && K0 > Estocastico_Nivel_sobrecompra && D0 > Estocastico_Nivel_sobrecompra){
         return true;
      }else{
         return false;
      }
   }else{
      return true;
   }
}

bool CheckRsiFilter(int order_type){
   if (Rsi_ativado){
      double rsiValue = iRSI(_Symbol, _Period, Rsi_periodo, PRICE_CLOSE, 1);
      
      if (order_type == OP_BUY && rsiValue < Rsi_Nivel_sobrevenda){
         return true;
      }else if (order_type == OP_SELL && rsiValue > Rsi_Nivel_sobrecompra){
         return true;
      }else{
         return false;
      }
   }else{
      return true;
   }
}

  
