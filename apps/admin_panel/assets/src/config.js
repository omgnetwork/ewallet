import BORING_LOADING from '../public/images/boring_loading.gif';

export const FUN_LOADING_GIF = true;
export const LOADING_GIF_SRC = {
  BORING: [
    BORING_LOADING,
  ],
  FUN: [
    'https://media.giphy.com/media/xUOwGebPearJp3Qh6o/giphy.gif',
    'https://media.giphy.com/media/3o7abAHdYvZdBNnGZq/giphy.gif',
    'https://media.giphy.com/media/100QWMdxQJzQC4/giphy.gif',
    'https://media.giphy.com/media/l0Hee6sB3fXbAdhRK/giphy.gif',
    'https://media.giphy.com/media/ypqHf6pQ5kQEg/giphy.gif',
  ],
};

export const LOADING_GIF = FUN_LOADING_GIF ? LOADING_GIF_SRC.FUN : LOADING_GIF_SRC.BORING;
