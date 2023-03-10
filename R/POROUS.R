#' The SOC decomposition model
#'
#' This function implements with the SoilR model development framework the dual porosity model described in Meurer et al. (2020).
#' The model is an evolution of a two-pool linear SOC model, with two pools (young and old material9) running in parallel for micro and mesopores.
#' While aboveground inputs are rooted in the mesopores, root inputs are distributed between micro and mesopores depending on porosity, which is in turn influenced by organic matter. This makes the model nonlinear, although it still behaves similarly to a linear model within a reasonable calibration range. The model is described by a series of four equations: \cr
#' \cr
#' \eqn{\frac{dM_{Y_{(mes)}}}{dt} = I_m + \left( \frac{\phi_{mes}}{\phi_{mes}+\phi_{mic}}\right) \cdot I_r - k_Y \cdot M_{Y_{(mes)}}+ T_Y } \cr
#' \eqn{ \frac{dM_{O_{(mes)}}}{dt} = \left( \epsilon \cdot k_Y \cdot M_{Y_{(mes)}} \right) - \left( (1- \epsilon) \cdot k_O \cdot M_{O_{(mes)}} \right) + T_O} \cr
#' \eqn{ \frac{dM_{Y_{(mic)}}}{dt} = \left( \frac{\phi_{mic}}{\phi_{mes}+\phi_{mic}}\right) \cdot I_r - k_Y \cdot F_{prot} \cdot M_{Y_{(mes)}}- T_Y } \cr
#' \eqn{ \frac{dM_{O_{(mic)}}}{dt} = \left( \epsilon \cdot k_Y \cdot F_{prot} \cdot M_{Y_{(mes)}} \right) - \left( (1- \epsilon) \cdot k_O \cdot F_{prot} \cdot M_{O_{(mes)}} \right) - T_O } \cr
#'  \cr
#' Please refer to the original paper for more details.  \cr
#'  \cr
#' The two porosity terms, \eqn{\phi_{mes} = f(M_{Y_{(mes)}}, M_{O_{(mes)}},M_{Y_{(mic)}}, M_{O_{(mic)}})} and \eqn{\phi_{mic} = f(M_{Y_{(mic)}}, M_{O_{(mic)}})}, are dependent on the variation of the different C pools and everything is variable over time, introducing a nonlinearity in the system and defining the biggest peculiarity of this model.  \cr
#' After substitutung the terms \eqn{\left( \frac{\phi_{mes}(t)}{\phi_{mes}(t)+\phi_{mic}(t)}\right) = \varphi_{mes}} and \eqn{\left( \frac{\phi_{mic}(t)}{\phi_{mes}(t)+\phi_{mic}(t)}\right) = \varphi_{mic}},
#' The model can be rewritten in matrix form as :  \cr
#'  \cr
#' \eqn{I_m(t) + I_r(t) \cdot N(C,t) + A(t) \cdot P(t) \cdot C(t)} \cr
#' Or, more explicitly:  \cr
#'  \cr
#'  \eqn{\frac{dC}{dt}=\begin{bmatrix} I_m\\ 0\\ 0\\ 0\\ \end{bmatrix}+   \begin{bmatrix} I_r\\ 0\\ I_r\\ 0\\ \end{bmatrix} \cdot \begin{bmatrix} \varphi_{mes} & 0 & 0 & 0\\ 0 & 1 & 0 & 0\\ 0 & 0 & \varphi_{mic} & 0\\ 0 & 0 & 0 & 1\\ \end{bmatrix}+   \begin{bmatrix} -k_y & \epsilon & 0 & 0\\ 0 & -k_o & 0 & 0\\ T_Y & 0 & -k_y & \epsilon\\ 0 & T_O & 0 & -k_o\\ \end{bmatrix} \cdot \begin{bmatrix} 1 & 0 & 0 & 0\\ 0 & 1 & 0 & 0\\ 0 & 0 & F_{prot} & 0\\ 0 & 0 & 0 & F_{prot}\\ \end{bmatrix} \cdot \begin{bmatrix} M_{Y_{mes}}\\ M_{O_{mes}}\\ M_{Y_{mic}}\\ M_{O_{mic}} \end{bmatrix} }
#'
#' @param ky decomposition constant of the Young pool
#' @param ko decomposition constant of the Old pool
#' @param kmix mixing rate
#' @param e efficiency, which is the transfer term between the pools and corresponds to the term h in the ICBM model in K??tterer et al. (2001)
#' @param Im Inputs from aboveground
#' @param Ir Inputs from roots
#' @param F_prot protection provided by the micropore space
#' @param proportion this is the linearization term. If NULL (or not specified, since default is NULL) then the model is running as nonlinear, as in the original paper. If specified (must be between 0 and 1) then the model is linearized adopting this value as fixed proportion of inputs from roots going into the mesopore space (and its reciprocal into the micropore)
#' @inheritParams pore_frac
#' @inheritParams Delta_z
#' @inheritParams f_text_mic
#' @return two values, the proportion of input in the mesopore and micropore Y pools
#'
#' @references Meurer, Katharina Hildegard Elisabeth, Claire Chenu, Elsa Coucheney, Anke Marianne Herrmann, Thomas Keller, Thomas K??tterer, David Nimblad Svensson, and Nicholas Jarvis. ???Modelling Dynamic Interactions between Soil Structure and the Storage and Turnover of Soil Organic Matter.??? Biogeosciences 17, no. 20 (October 19, 2020): 5025???42. https://doi.org/10.5194/bg-17-5025-2020. \cr
#' K??tterer, Thomas, and Olof Andr??n. ???The ICBM Family of Analytically Solved Models of Soil Carbon, Nitrogen and Microbial Biomass Dynamics ??? Descriptions and Application Examples.??? Ecological Modelling 136, no. 2???3 (January 2001): 191???207. https://doi.org/10.1016/S0304-3800(00)00420-8.
#' @export
#'
Porous<-function(ky=0.8, ko=0.00605,
                 kmix=0.9,
                 e=0.13,
                 Im=1.1, Ir=0.5,
                 F_prot=0.0,
                 phi_mac=0.2,
                 clay=0.2,
                 Delta_z_min=20,
                 gamma_o=1.2,
                 proportion=NULL){

  time_symbol='t'



  ##### IN
  ifs=SoilR:::InFluxList_by_PoolName(
    c(
      SoilR:::InFlux_by_PoolName(
        destinationName='My_mes',
        func=function(t){
          Im
        }
      ),

    if(is.null(proportion)){ #if cycle for inputs going to My_mes, if linear or not. If "proportion" is missing then nonlinear
      SoilR:::InFlux_by_PoolName(
        destinationName='My_mes',
        func=function(t, My_mes, Mo_mes, My_mic, Mo_mic){
          Ir*pore_frac(phi_mac, clay, Delta_z_min, gamma_o, My_mes, Mo_mes, My_mic, Mo_mic)[1]
        }
      )
    } else{ #... else use the proportion
      SoilR:::InFlux_by_PoolName(
        destinationName='My_mes',
        func=function(t, My_mes, Mo_mes, My_mic, Mo_mic){
          Ir*proportion
        }
      )
    }
        ,
    if(is.null(proportion)){#if cycle for inputs going to My_ic, if linear or not. If "proportion" is missing then nonlinear
      SoilR:::InFlux_by_PoolName(
        destinationName='My_mic',
        func=function(t, My_mes, Mo_mes, My_mic, Mo_mic){
          Ir*pore_frac(phi_mac, clay, Delta_z_min, gamma_o, My_mes, Mo_mes, My_mic, Mo_mic)[2]
        }
      )
    } else {#... else use the reciprocal of the proportion
      SoilR:::InFlux_by_PoolName(
        destinationName='My_mic',
        func=function(t, My_mes, Mo_mes, My_mic, Mo_mic){
          Ir*(1-proportion)
        }
      )
    }
    )
  )
  ##### OUT
  ofs=SoilR:::OutFluxList_by_PoolName(
    c(
      SoilR:::OutFlux_by_PoolName(
        sourceName='My_mes',
        func=function(My_mes){
          ky*My_mes
        }
      )
      ,
      SoilR:::OutFlux_by_PoolName(
        sourceName='Mo_mes',
        func=function(Mo_mes){
          (1-e)*ko*Mo_mes
        }
      ),
      SoilR:::OutFlux_by_PoolName(
        sourceName='My_mic',
        func=function(My_mic){
          ky*F_prot*My_mic
        }
      ),
      SoilR:::OutFlux_by_PoolName(
        sourceName='Mo_mic',
        func=function(Mo_mic){
          (1-e)*ko*F_prot*Mo_mic
        }
      ),
      # Bioturbation, nonlinearity here, Ty and To are outfluxes from the micropores (and also internal fluxes below, into My_mes and Mo_mes)
      #Ty
      SoilR:::OutFlux_by_PoolName(
        sourceName='My_mic',
        func=function(My_mic,My_mes){
          kmix*((My_mic-My_mes)/2)
        }
      ),
      #To
      SoilR:::OutFlux_by_PoolName(
        sourceName='Mo_mic',
        func=function(Mo_mic,Mo_mes){
          kmix*((Mo_mic-Mo_mes)/2)
        }
      )
    )
  )

  ##### INT
  intfs=SoilR:::InternalFluxList_by_PoolName(
    list(
      SoilR:::InternalFlux_by_PoolName(
        sourceName='My_mes',
        destinationName='Mo_mes',
        func=function(My_mes){
          e*ky*My_mes
        }
      ),
      SoilR:::InternalFlux_by_PoolName(
        sourceName='My_mic',
        destinationName='Mo_mic',
        func=function(My_mic){
          e*ky*F_prot*My_mic
        }
      ),
      #bioturbation fluxes
      #Ty
      SoilR:::InternalFlux_by_PoolName(
        sourceName='My_mic',
        destinationName='My_mes',
        func=function(My_mic, My_mes){
          kmix*((My_mic-My_mes)/2)
        }
      ),
      #To
      SoilR:::InternalFlux_by_PoolName(
        sourceName='Mo_mic',
        destinationName='Mo_mes',
        func=function(Mo_mic, Mo_mes){
          kmix*((Mo_mic-Mo_mes)/2)
        }
      )
    )
  )

  smod <- SoilR:::SymbolicModel_by_PoolNames(
    in_fluxes=ifs,
    internal_fluxes=intfs,
    out_fluxes=ofs,
    timeSymbol=time_symbol
  )
  smod
}




