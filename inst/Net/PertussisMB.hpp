namespace SDE {
double Born(double *Value, map <std::string,int>& NumTrans,  map <std::string,int>& NumPlaces,const vector <string>& NameTrans, const struct InfTr* Trans, const int Tran, const double& Time);
double Death(double *Value, map <std::string,int>& NumTrans,  map <std::string,int>& NumPlaces,const vector <string>& NameTrans, const struct InfTr* Trans, const int Tran, const double& Time);
double D(double *Value, map <std::string,int>& NumTrans,  map <std::string,int>& NumPlaces,const vector <string>& NameTrans, const struct InfTr* Trans, const int Tran, const double& Time);
double lambda(double *Value, map <std::string,int>& NumTrans,  map <std::string,int>& NumPlaces,const vector <string>& NameTrans, const struct InfTr* Trans, const int Tran, const double& Time);
double vaccine(double *Value, map <std::string,int>& NumTrans,  map <std::string,int>& NumPlaces,const vector <string>& NameTrans, const struct InfTr* Trans, const int Tran, const double& Time);
double vaccine_failure(double *Value, map <std::string,int>& NumTrans,  map <std::string,int>& NumPlaces,const vector <string>& NameTrans, const struct InfTr* Trans, const int Tran, const double& Time);
};
