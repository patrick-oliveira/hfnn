{-# LANGUAGE RankNTypes #-}
module AI.HFNN.Activation (
  ActivationFunction(..),
  modifiedCuberoot,
  logistic,
  relu,
  softplus
 ) where

import qualified Data.ByteString as BS

data DerivativeBase = X | Y deriving (Ord,Eq)

data ActivationFunction = ActivationFunction {
  activationFunction :: [Double] -> [(Double, Double)],
  glActivationFunction :: Maybe BS.ByteString
 }

nogl :: ActivationFunction
nogl = let
  errortext = "No GLSL template used directly"
  in ActivationFunction (error errortext) Nothing

-- | Experimental activation function based on cube root. It should be less
-- prone to the vanishing gradient problem than the logistic function and other
-- sigmoid functions, and unlike cube root itself the derivative is never 1/0.
modifiedCuberoot :: ActivationFunction
modifiedCuberoot = nogl {
  activationFunction = map $ \x' -> let
    x = abs x'
    crt = x ** (1/3)
    sr3 = 3 ** (1/2)
    in (signum x' * (
      crt - (atan (sr3 * crt))/sr3
     ), 1 / (3 * x**(2/3) + 1))
 }

logistic :: ActivationFunction
logistic = nogl {
  activationFunction = map $ \x -> let
    y = 1 / (1 + exp (-x))
    in (y, y * (1 - y))
 }

relu :: ActivationFunction 
relu = nogl {
  activationFunction = map $ \x -> if x < 0
    then (0, 0)
    else (x, 1)
 }

softplus :: ActivationFunction
softplus = nogl {
  activationFunction = map $ \x -> (log (1 + exp x), 1 / (1 + exp (-x)))
 }

softmax :: ActivationFunction
softmax = nogl {
  activationFunction = \z -> let
    ez = map exp z
    d = sum ez
    in map (\q -> let
      s = q / d
      in (s, s * (1 - s))) ez
 }